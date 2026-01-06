{{- config(
    materialized='incremental',
    unique_key='order_key',
    alias='dim_orders',
    tags=['mart', 'dimension', 'order']
) -}}

with hub_order as (
    select * from {{ ref('hub_order') }}
),

sat_order as (
    select * from {{ ref('sat_order') }}
    qualify row_number() over (partition by order_hk order by load_date desc) = 1
),

sat_order_calculated as (
    select * from {{ ref('sat_order_calculated') }}
),

link_order_customer as (
    select * from {{ ref('link_order_customer') }}
),

hub_customer as (
    select * from {{ ref('hub_customer') }}
),

sat_customer as (
    select * from {{ ref('sat_customer') }}
    qualify row_number() over (partition by customer_hk order by load_date desc) = 1
),

sat_customer_derived as (
    select * from {{ ref('sat_customer_derived') }}
),

enriched_orders as (
    select
        ho.order_key,
        loc.customer_hk,
        hc.customer_key,
        so.order_status,
        so.total_price,
        so.order_date,
        so.order_priority,
        so.clerk,
        so.ship_priority,
        so.order_comment,
        sc.customer_name,
        sc.nation_key,
        scd.value_segment,
        soc.order_status_desc,
        soc.order_year,
        soc.order_quarter,
        soc.order_month,
        greatest(
            coalesce(so.load_date, '1900-01-01'::timestamp_ntz),
            coalesce(soc.load_date, '1900-01-01'::timestamp_ntz)
        ) as _loaded_at,
        current_timestamp() as _updated_at

    from hub_order ho
    inner join sat_order so
        on ho.order_hk = so.order_hk
    left join sat_order_calculated soc
        on ho.order_hk = soc.order_hk
    left join link_order_customer loc
        on ho.order_hk = loc.order_hk
    left join hub_customer hc
        on loc.customer_hk = hc.customer_hk
    left join sat_customer sc
        on hc.customer_hk = sc.customer_hk
    left join sat_customer_derived scd
        on hc.customer_hk = scd.customer_hk

    {% if is_incremental() %}
    where greatest(
        coalesce(so.load_date, '1900-01-01'::timestamp_ntz),
        coalesce(soc.load_date, '1900-01-01'::timestamp_ntz)
    ) > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select * from enriched_orders
