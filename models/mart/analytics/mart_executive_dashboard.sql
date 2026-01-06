{{- config(
    materialized='table',
    alias='executive_dashboard',
    tags=['mart', 'analytics', 'dashboard']
) -}}

with orders as (
    select
        order_key,
        customer_key,
        order_date,
        order_year,
        order_month,
        order_quarter,
        order_status,
        total_price
    from {{ ref('mart_dim_orders') }}
),

order_lines as (
    select
        order_key,
        final_price
    from {{ ref('mart_fct_order_lines') }}
),

daily_metrics as (
    select
        o.order_date,
        o.order_year,
        o.order_month,
        o.order_quarter,
        sum(ol.final_price) as daily_revenue,
        count(distinct o.order_key) as daily_orders,
        count(distinct o.customer_key) as daily_active_customers,
        avg(o.total_price) as daily_avg_order_value,
        sum(case when o.order_status = 'O' then ol.final_price else 0 end) as open_revenue,
        sum(case when o.order_status = 'F' then ol.final_price else 0 end) as fulfilled_revenue,
        sum(case when o.order_status = 'P' then ol.final_price else 0 end) as partial_revenue,
        lag(sum(ol.final_price)) over (order by o.order_date) as prev_day_revenue,
        avg(sum(ol.final_price)) over (
            order by o.order_date
            rows between 6 preceding and current row
        ) as seven_day_avg_revenue

    from orders o
    inner join order_lines ol
        on o.order_key = ol.order_key
    group by o.order_date, o.order_year, o.order_month, o.order_quarter
),

executive_kpis as (
    select
        order_date as metric_date,
        daily_revenue as total_revenue,
        daily_orders as total_orders,
        round(daily_avg_order_value, 2) as avg_order_value,
        daily_active_customers as active_customers,
        seven_day_avg_revenue,
        case
            when prev_day_revenue > 0
            then round(((daily_revenue - prev_day_revenue) / prev_day_revenue) * 100, 2)
            else null
        end as daily_revenue_growth_pct,
        round(daily_revenue / nullif(daily_orders, 0), 2) as revenue_per_order,
        round(daily_revenue / nullif(daily_active_customers, 0), 2) as revenue_per_customer,
        round((fulfilled_revenue / nullif(daily_revenue, 0)) * 100, 1) as fulfillment_rate_pct,
        round((open_revenue / nullif(daily_revenue, 0)) * 100, 1) as open_orders_pct,
        round((partial_revenue / nullif(daily_revenue, 0)) * 100, 1) as partial_orders_pct,
        case
            when daily_revenue > seven_day_avg_revenue * 1.2 then 'Excellent'
            when daily_revenue > seven_day_avg_revenue * 1.1 then 'Good'
            when daily_revenue > seven_day_avg_revenue * 0.9 then 'Average'
            else 'Below Average'
        end as performance_rating,
        case
            when daily_revenue > prev_day_revenue then '↗️ Increasing'
            when daily_revenue < prev_day_revenue then '↘️ Decreasing'
            else '➡️ Stable'
        end as trend,
        order_year as year,
        order_quarter as quarter,
        order_month as month

    from daily_metrics
)

select *
from executive_kpis
order by metric_date desc
