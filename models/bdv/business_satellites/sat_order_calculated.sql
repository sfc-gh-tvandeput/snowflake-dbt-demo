{{- config(
    materialized='incremental',
    unique_key='ORDER_HK',
    tags=['bdv', 'business_satellite', 'tpc_h']
) -}}

WITH order_line_items AS (
    SELECT
        ho.ORDER_HK,
        ho.LOAD_DATE,
        SUM(li.QUANTITY) AS total_quantity,
        COUNT(DISTINCT hl.LINE_NUMBER) AS line_item_count,
        SUM(li.EXTENDED_PRICE) AS total_extended_price,
        SUM(li.EXTENDED_PRICE * li.DISCOUNT) AS total_discount_amount,
        SUM(li.EXTENDED_PRICE * (1 - li.DISCOUNT) * li.TAX) AS total_tax_amount,
        SUM(li.EXTENDED_PRICE * (1 - li.DISCOUNT)) AS net_amount,
        SUM(li.EXTENDED_PRICE * (1 - li.DISCOUNT) * (1 + li.TAX)) AS total_amount,
        AVG(li.EXTENDED_PRICE) AS avg_line_price,
        MIN(li.SHIP_DATE) AS first_ship_date,
        MAX(li.SHIP_DATE) AS last_ship_date,
        DATEDIFF(DAY, MIN(li.SHIP_DATE), MAX(li.SHIP_DATE)) AS fulfillment_span_days
    FROM {{ ref('hub_order') }} ho
    LEFT JOIN {{ ref('link_lineitem_order') }} llo
        ON ho.ORDER_HK = llo.ORDER_HK
    LEFT JOIN {{ ref('hub_lineitem') }} hl
        ON llo.LINEITEM_HK = hl.LINEITEM_HK
    LEFT JOIN {{ ref('sat_lineitem') }} li
        ON hl.LINEITEM_HK = li.LINEITEM_HK
    {% if is_incremental() %}
    WHERE ho.LOAD_DATE > (SELECT MAX(LOAD_DATE) FROM {{ this }})
    {% endif %}
    GROUP BY ho.ORDER_HK, ho.LOAD_DATE
),

order_enriched AS (
    SELECT
        oli.*,
        so.ORDER_STATUS,
        so.ORDER_PRIORITY,
        so.ORDER_DATE,
        so.TOTAL_PRICE,
        so.CLERK,
        so.SHIP_PRIORITY,
        -- Match legacy dim_orders order_status_desc values exactly
        CASE
            WHEN so.ORDER_STATUS = 'O' THEN 'Open'
            WHEN so.ORDER_STATUS = 'F' THEN 'Fulfilled'
            WHEN so.ORDER_STATUS = 'P' THEN 'Partial'
            ELSE 'Unknown'
        END AS order_status_desc,
        -- Date dimensions for analytics (matching legacy)
        EXTRACT(YEAR FROM so.ORDER_DATE) AS order_year,
        EXTRACT(QUARTER FROM so.ORDER_DATE) AS order_quarter,
        EXTRACT(MONTH FROM so.ORDER_DATE) AS order_month,
        -- Priority level classification
        CASE
            WHEN so.ORDER_PRIORITY = '1-URGENT' THEN 'Urgent'
            WHEN so.ORDER_PRIORITY = '2-HIGH' THEN 'High'
            WHEN so.ORDER_PRIORITY = '3-MEDIUM' THEN 'Medium'
            WHEN so.ORDER_PRIORITY IN ('4-NOT SPECIFIED', '5-LOW') THEN 'Low'
            ELSE 'Unknown'
        END AS priority_level,
        -- Fulfillment metrics
        DATEDIFF(DAY, so.ORDER_DATE, oli.first_ship_date) AS days_to_first_ship,
        CASE
            WHEN oli.first_ship_date IS NULL THEN 'Not Shipped'
            WHEN DATEDIFF(DAY, so.ORDER_DATE, oli.first_ship_date) <= 7 THEN 'Fast'
            WHEN DATEDIFF(DAY, so.ORDER_DATE, oli.first_ship_date) <= 14 THEN 'Normal'
            ELSE 'Slow'
        END AS fulfillment_speed
    FROM order_line_items oli
    LEFT JOIN {{ ref('sat_order') }} so
        ON oli.ORDER_HK = so.ORDER_HK
),

hashed_records AS (
    SELECT
        oe.*,
        {{ dbt_utils.generate_surrogate_key([
            'COALESCE(total_quantity, 0)',
            'COALESCE(line_item_count, 0)',
            'COALESCE(net_amount, 0)',
            'COALESCE(total_amount, 0)',
            'COALESCE(fulfillment_span_days, 0)',
            'COALESCE(days_to_first_ship, 0)',
            'fulfillment_speed',
            'order_status_desc',
            'priority_level',
            'order_year',
            'order_quarter',
            'order_month'
        ]) }} AS ORDER_CALCULATED_HASHDIFF
    FROM order_enriched oe
)

SELECT
    ORDER_HK,
    ORDER_CALCULATED_HASHDIFF,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(line_item_count, 0) AS line_item_count,
    COALESCE(total_extended_price, 0) AS total_extended_price,
    COALESCE(total_discount_amount, 0) AS total_discount_amount,
    COALESCE(total_tax_amount, 0) AS total_tax_amount,
    COALESCE(net_amount, 0) AS net_amount,
    COALESCE(total_amount, 0) AS total_amount,
    COALESCE(avg_line_price, 0) AS avg_line_price,
    first_ship_date,
    last_ship_date,
    COALESCE(fulfillment_span_days, 0) AS fulfillment_span_days,
    ORDER_STATUS,
    ORDER_PRIORITY,
    ORDER_DATE,
    TOTAL_PRICE,
    CLERK,
    SHIP_PRIORITY,
    order_status_desc,
    order_year,
    order_quarter,
    order_month,
    priority_level,
    days_to_first_ship,
    fulfillment_speed,
    LOAD_DATE,
    'DERIVED' AS RECORD_SOURCE
FROM hashed_records

{% if is_incremental() %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ORDER_HK
    ORDER BY LOAD_DATE DESC
) = 1
{% endif %}
