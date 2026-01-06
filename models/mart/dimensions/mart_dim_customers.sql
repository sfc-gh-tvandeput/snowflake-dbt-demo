{{- config(
    materialized='incremental',
    unique_key='customer_key',
    alias='dim_customers',
    tags=['mart', 'dimension', 'customer']
) -}}

with hub_customer as (
    select * from {{ ref('hub_customer') }}
),

sat_customer as (
    select * from {{ ref('sat_customer') }}
    qualify row_number() over (partition by customer_hk order by load_date desc) = 1
),

sat_customer_derived as (
    select * from {{ ref('sat_customer_derived') }}
),

sat_nation as (
    select * from {{ ref('sat_nation') }}
    qualify row_number() over (partition by nation_hk order by load_date desc) = 1
),

hub_nation as (
    select * from {{ ref('hub_nation') }}
),

enriched_customers as (
    select
        hc.customer_key,
        sc.customer_name,
        sc.customer_address,
        sc.customer_phone,
        sc.account_balance,
        sc.market_segment,
        sc.customer_comment,
        sc.nation_key,
        sn.nation_name,
        hn.nation_key as region_key,
        scd.total_orders,
        scd.open_orders,
        scd.has_orders_flag,
        scd.has_open_orders_flag,
        scd.value_segment,
        greatest(
            coalesce(sc.load_date, '1900-01-01'::timestamp_ntz),
            coalesce(scd.load_date, '1900-01-01'::timestamp_ntz)
        ) as _loaded_at,
        current_timestamp() as _updated_at

    from hub_customer hc
    inner join sat_customer sc
        on hc.customer_hk = sc.customer_hk
    left join sat_customer_derived scd
        on hc.customer_hk = scd.customer_hk
    left join hub_nation hn
        on sc.nation_key = hn.nation_key
    left join sat_nation sn
        on hn.nation_hk = sn.nation_hk

    {% if is_incremental() %}
    where greatest(
        coalesce(sc.load_date, '1900-01-01'::timestamp_ntz),
        coalesce(scd.load_date, '1900-01-01'::timestamp_ntz)
    ) > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select * from enriched_customers
