{{- config(
    materialized='incremental',
    unique_key='LINEITEM_HK',
    tags=['bdv', 'business_satellite', 'tpc_h']
) -}}

WITH lineitem_base AS (
    SELECT
        hl.LINEITEM_HK,
        hl.LOAD_DATE,
        li.QUANTITY,
        li.EXTENDED_PRICE,
        li.DISCOUNT,
        li.TAX,
        li.RETURN_FLAG,
        li.LINE_STATUS,
        li.SHIP_DATE,
        li.COMMIT_DATE,
        li.RECEIPT_DATE,
        li.SHIP_INSTRUCT,
        li.SHIP_MODE,
        p.PART_NAME,
        p.BRAND AS PART_BRAND,
        p.PART_TYPE,
        p.PART_SIZE,
        soc.ORDER_DATE
    FROM {{ ref('hub_lineitem') }} hl
    INNER JOIN {{ ref('sat_lineitem') }} li
        ON hl.LINEITEM_HK = li.LINEITEM_HK
    LEFT JOIN {{ ref('link_lineitem_product') }} llp
        ON hl.LINEITEM_HK = llp.LINEITEM_HK
    LEFT JOIN {{ ref('hub_product') }} hp
        ON llp.PART_HK = hp.PART_HK
    LEFT JOIN {{ ref('sat_product') }} p
        ON hp.PART_HK = p.PART_HK
    LEFT JOIN {{ ref('link_lineitem_order') }} llo
        ON hl.LINEITEM_HK = llo.LINEITEM_HK
    LEFT JOIN {{ ref('hub_order') }} ho
        ON llo.ORDER_HK = ho.ORDER_HK
    LEFT JOIN {{ ref('sat_order_calculated') }} soc
        ON ho.ORDER_HK = soc.ORDER_HK
    {% if is_incremental() %}
    WHERE hl.LOAD_DATE > (SELECT MAX(LOAD_DATE) FROM {{ this }})
    {% endif %}
),

fx_rates AS (
    SELECT * FROM {{ ref('int_fx_rates__daily') }}
),

lineitem_enriched AS (
    SELECT
        lb.LINEITEM_HK,
        lb.LOAD_DATE,
        lb.EXTENDED_PRICE AS original_price,
        lb.EXTENDED_PRICE * (1 - lb.DISCOUNT) AS net_price,
        lb.EXTENDED_PRICE * (1 - lb.DISCOUNT) * (1 + lb.TAX) AS total_price,
        'USD' AS source_currency,
        1.0 AS fx_rate_to_usd,
        lb.EXTENDED_PRICE * (1 - lb.DISCOUNT) AS net_price_usd,
        lb.QUANTITY * lb.EXTENDED_PRICE * (1 - lb.DISCOUNT) AS line_total_usd,
        lb.EXTENDED_PRICE * lb.DISCOUNT AS discount_amount,
        lb.EXTENDED_PRICE * (1 - lb.DISCOUNT) * lb.TAX AS tax_amount,
        COALESCE(fx.conversion_rate, 1.0) AS eur_conversion_rate,
        (lb.EXTENDED_PRICE * (1 - lb.DISCOUNT) * (1 + lb.TAX)) * COALESCE(fx.conversion_rate, 1.0) AS total_price_eur,
        DATEDIFF(DAY, lb.COMMIT_DATE, lb.SHIP_DATE) AS days_early_late,
        CASE
            WHEN lb.SHIP_DATE <= lb.COMMIT_DATE THEN 'ON_TIME'
            WHEN DATEDIFF(DAY, lb.COMMIT_DATE, lb.SHIP_DATE) <= 3 THEN 'SLIGHTLY_LATE'
            ELSE 'LATE'
        END AS delivery_performance,
        CASE
            WHEN lb.RETURN_FLAG = 'R' THEN 'RETURNED'
            WHEN lb.RETURN_FLAG = 'A' THEN 'ACCEPTED'
            WHEN lb.RETURN_FLAG = 'N' THEN 'NOT_RETURNED'
            ELSE 'UNKNOWN'
        END AS return_status,
        CASE
            WHEN lb.LINE_STATUS = 'O' THEN 'OUTSTANDING'
            WHEN lb.LINE_STATUS = 'F' THEN 'FULFILLED'
            ELSE 'UNKNOWN'
        END AS line_status_description
    FROM lineitem_base lb
    LEFT JOIN fx_rates fx
        ON fx.from_currency = 'USD'
        AND fx.to_currency = 'EUR'
        AND lb.ORDER_DATE BETWEEN fx.day_dt AND fx.end_date
),

hashed_records AS (
    SELECT
        le.*,
        {{ dbt_utils.generate_surrogate_key([
            'net_price_usd',
            'line_total_usd',
            'discount_amount',
            'tax_amount',
            'fx_rate_to_usd',
            'eur_conversion_rate',
            'total_price_eur',
            'COALESCE(days_early_late, 0)',
            'delivery_performance',
            'return_status',
            'line_status_description'
        ]) }} AS LINEITEM_ENRICHED_HASHDIFF
    FROM lineitem_enriched le
)

SELECT
    LINEITEM_HK,
    LINEITEM_ENRICHED_HASHDIFF,
    original_price,
    net_price,
    total_price,
    source_currency,
    fx_rate_to_usd,
    net_price_usd,
    line_total_usd,
    discount_amount,
    tax_amount,
    eur_conversion_rate,
    total_price_eur,
    days_early_late,
    delivery_performance,
    return_status,
    line_status_description,
    LOAD_DATE,
    'DERIVED' AS RECORD_SOURCE
FROM hashed_records

{% if is_incremental() %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY LINEITEM_HK
    ORDER BY LOAD_DATE DESC
) = 1
{% endif %}
