{{- config(
    materialized='incremental',
    unique_key=['order_key', 'line_number'],
    alias='fct_order_lines',
    tags=['mart', 'fact', 'order']
) -}}

with hub_lineitem as (
    select
        lineitem_hk,
        line_number
    from {{ ref('hub_lineitem') }}
),

sat_lineitem as (
    select
        lineitem_hk,
        quantity,
        extended_price,
        discount,
        tax,
        return_flag,
        line_status,
        ship_date,
        commit_date,
        receipt_date,
        ship_instruct,
        ship_mode,
        line_comment,
        load_date
    from {{ ref('sat_lineitem') }}
    qualify row_number() over (partition by lineitem_hk order by load_date desc) = 1
),

sat_lineitem_enriched as (
    select
        lineitem_hk,
        net_price,
        total_price,
        eur_conversion_rate,
        total_price_eur,
        load_date
    from {{ ref('sat_lineitem_enriched') }}
),

link_lineitem_order as (
    select
        lineitem_hk,
        order_hk
    from {{ ref('link_lineitem_order') }}
),

hub_order as (
    select
        order_hk,
        order_key
    from {{ ref('hub_order') }}
),

sat_order_calculated as (
    select
        order_hk,
        order_date,
        order_status_desc,
        load_date
    from {{ ref('sat_order_calculated') }}
),

link_lineitem_product as (
    select
        lineitem_hk,
        part_hk
    from {{ ref('link_lineitem_product') }}
),

hub_product as (
    select
        part_hk,
        part_key
    from {{ ref('hub_product') }}
),

link_lineitem_supplier as (
    select
        lineitem_hk,
        supplier_hk
    from {{ ref('link_lineitem_supplier') }}
),

hub_supplier as (
    select
        supplier_hk,
        supplier_key
    from {{ ref('hub_supplier') }}
),

link_order_customer as (
    select
        order_hk,
        customer_hk
    from {{ ref('link_order_customer') }}
),

hub_customer as (
    select
        customer_hk,
        customer_key
    from {{ ref('hub_customer') }}
),

fact_order_lines as (
    select
        ho.order_key,
        hl.line_number,
        hp.part_key,
        hs.supplier_key,
        hc.customer_key,
        sli.quantity as quantity,
        sli.extended_price,
        sli.discount,
        sli.tax,
        sle.net_price as discounted_price,
        sle.total_price as final_price,
        sle.eur_conversion_rate,
        sle.total_price_eur as final_price_eur,
        sli.return_flag,
        sli.line_status,
        sli.ship_date,
        sli.commit_date,
        sli.receipt_date,
        sli.ship_instruct,
        sli.ship_mode,
        sli.line_comment,
        soc.order_date,
        soc.order_status_desc,
        greatest(
            coalesce(sli.load_date, '1900-01-01'::timestamp_ntz),
            coalesce(sle.load_date, '1900-01-01'::timestamp_ntz),
            coalesce(soc.load_date, '1900-01-01'::timestamp_ntz)
        ) as _loaded_at,
        current_timestamp() as _updated_at

    from hub_lineitem hl
    inner join sat_lineitem sli
        on hl.lineitem_hk = sli.lineitem_hk
    left join sat_lineitem_enriched sle
        on hl.lineitem_hk = sle.lineitem_hk
    inner join link_lineitem_order llo
        on hl.lineitem_hk = llo.lineitem_hk
    inner join hub_order ho
        on llo.order_hk = ho.order_hk
    left join sat_order_calculated soc
        on ho.order_hk = soc.order_hk
    left join link_lineitem_product llp
        on hl.lineitem_hk = llp.lineitem_hk
    left join hub_product hp
        on llp.part_hk = hp.part_hk
    left join link_lineitem_supplier lls
        on hl.lineitem_hk = lls.lineitem_hk
    left join hub_supplier hs
        on lls.supplier_hk = hs.supplier_hk
    left join link_order_customer loc
        on ho.order_hk = loc.order_hk
    left join hub_customer hc
        on loc.customer_hk = hc.customer_hk

    {% if is_incremental() %}
    where greatest(
        coalesce(sli.load_date, '1900-01-01'::timestamp_ntz),
        coalesce(sle.load_date, '1900-01-01'::timestamp_ntz),
        coalesce(soc.load_date, '1900-01-01'::timestamp_ntz)
    ) > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select * from fact_order_lines
