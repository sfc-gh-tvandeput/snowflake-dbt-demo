{{- config(
    materialized='incremental',
    unique_key='CUSTOMER_HK',
    tags=['bdv', 'business_satellite', 'tpc_h']
) -}}

WITH customer_orders AS (
    SELECT
        hc.CUSTOMER_HK,
        hc.LOAD_DATE,
        COUNT(DISTINCT ho.ORDER_KEY) AS total_orders,
        COUNT(DISTINCT CASE WHEN o.ORDER_STATUS = 'O' THEN ho.ORDER_KEY END) AS open_orders,
        SUM(l.EXTENDED_PRICE * (1 - l.DISCOUNT)) AS total_spent,
        AVG(l.EXTENDED_PRICE * (1 - l.DISCOUNT)) AS avg_order_value,
        MIN(o.ORDER_DATE) AS first_order_date,
        MAX(o.ORDER_DATE) AS last_order_date,
        DATEDIFF(DAY, MIN(o.ORDER_DATE), MAX(o.ORDER_DATE)) AS customer_tenure_days,
        CASE
            WHEN COUNT(DISTINCT ho.ORDER_KEY) = 0 THEN 0
            WHEN DATEDIFF(DAY, MIN(o.ORDER_DATE), MAX(o.ORDER_DATE)) = 0 THEN 0
            ELSE ROUND(COUNT(DISTINCT ho.ORDER_KEY)::FLOAT / NULLIF(DATEDIFF(DAY, MIN(o.ORDER_DATE), MAX(o.ORDER_DATE)), 0) * 365, 2)
        END AS orders_per_year
    FROM {{ ref('hub_customer') }} hc
    LEFT JOIN {{ ref('link_order_customer') }} loc
        ON hc.CUSTOMER_HK = loc.CUSTOMER_HK
    LEFT JOIN {{ ref('hub_order') }} ho
        ON loc.ORDER_HK = ho.ORDER_HK
    LEFT JOIN {{ ref('sat_order') }} o
        ON ho.ORDER_HK = o.ORDER_HK
    LEFT JOIN {{ ref('link_lineitem_order') }} llo
        ON ho.ORDER_HK = llo.ORDER_HK
    LEFT JOIN {{ ref('hub_lineitem') }} hl
        ON llo.LINEITEM_HK = hl.LINEITEM_HK
    LEFT JOIN {{ ref('sat_lineitem') }} l
        ON hl.LINEITEM_HK = l.LINEITEM_HK
    {% if is_incremental() %}
    WHERE hc.LOAD_DATE > (SELECT MAX(LOAD_DATE) FROM {{ this }})
    {% endif %}
    GROUP BY hc.CUSTOMER_HK, hc.LOAD_DATE
),

customer_attributes AS (
    SELECT
        hc.CUSTOMER_HK,
        sc.ACCOUNT_BALANCE
    FROM {{ ref('hub_customer') }} hc
    INNER JOIN {{ ref('sat_customer') }} sc
        ON hc.CUSTOMER_HK = sc.CUSTOMER_HK
),

customer_enriched AS (
    SELECT
        co.*,
        ca.ACCOUNT_BALANCE,
        -- Business flags (matching legacy dim_customers)
        CASE
            WHEN co.total_orders > 0 THEN 'Y'
            ELSE 'N'
        END AS has_orders_flag,
        CASE
            WHEN co.open_orders > 0 THEN 'Y'
            ELSE 'N'
        END AS has_open_orders_flag,
        -- Value segment based on account_balance (matching legacy logic)
        CASE
            WHEN ca.ACCOUNT_BALANCE >= 5000 THEN 'High Value'
            WHEN ca.ACCOUNT_BALANCE >= 1000 THEN 'Medium Value'
            ELSE 'Standard'
        END AS value_segment,
        -- Additional status based on recency (keeping this as extra insight)
        CASE
            WHEN co.total_orders = 0 THEN 'Never Ordered'
            WHEN co.last_order_date IS NULL THEN 'Never Ordered'
            WHEN DATEDIFF(DAY, co.last_order_date, CURRENT_DATE()) <= 90 THEN 'Active'
            WHEN DATEDIFF(DAY, co.last_order_date, CURRENT_DATE()) <= 365 THEN 'At Risk'
            ELSE 'Churned'
        END AS customer_status
    FROM customer_orders co
    LEFT JOIN customer_attributes ca
        ON co.CUSTOMER_HK = ca.CUSTOMER_HK
),

hashed_records AS (
    SELECT
        ce.*,
        {{ dbt_utils.generate_surrogate_key([
            'COALESCE(total_orders, 0)',
            'COALESCE(open_orders, 0)',
            'COALESCE(total_spent, 0)',
            'COALESCE(avg_order_value, 0)',
            'COALESCE(orders_per_year, 0)',
            'COALESCE(ACCOUNT_BALANCE, 0)',
            'has_orders_flag',
            'has_open_orders_flag',
            'value_segment',
            'customer_status'
        ]) }} AS CUSTOMER_DERIVED_HASHDIFF
    FROM customer_enriched ce
)

SELECT
    CUSTOMER_HK,
    CUSTOMER_DERIVED_HASHDIFF,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(open_orders, 0) AS open_orders,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(avg_order_value, 0) AS avg_order_value,
    first_order_date,
    last_order_date,
    COALESCE(customer_tenure_days, 0) AS customer_tenure_days,
    COALESCE(orders_per_year, 0) AS orders_per_year,
    COALESCE(ACCOUNT_BALANCE, 0) AS account_balance,
    has_orders_flag,
    has_open_orders_flag,
    value_segment,
    customer_status,
    LOAD_DATE,
    'DERIVED' AS RECORD_SOURCE
FROM hashed_records

{% if is_incremental() %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY CUSTOMER_HK
    ORDER BY LOAD_DATE DESC
) = 1
{% endif %}
