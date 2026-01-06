{{- config(
    materialized='table',
    alias='customer_insights',
    tags=['mart', 'analytics', 'customer']
) -}}

with customers as (
    select * from {{ ref('mart_dim_customers') }}
),

nations as (
    select
        hn.nation_key,
        sn.nation_name,
        sn.nation_comment
    from {{ ref('hub_nation') }} hn
    inner join {{ ref('sat_nation') }} sn
        on hn.nation_hk = sn.nation_hk
),

customer_stats as (
    select
        c.customer_key,
        c.customer_name,
        c.account_balance,
        c.market_segment,
        c.nation_key,
        c.value_segment,
        avg(c.account_balance) over (partition by c.nation_key) as country_average_balance,
        c.account_balance - avg(c.account_balance) over (partition by c.nation_key) as balance_vs_country_average,
        percent_rank() over (order by c.account_balance) as balance_percentile,
        row_number() over (partition by c.nation_key order by c.account_balance desc) as rank_in_country,
        count(*) over (partition by c.nation_key) as total_customers_in_country
    from customers c
),

customer_base as (
    select
        cs.*,
        n.nation_name as country,
        case
            when cs.rank_in_country <= 10 then 'TOP_10_IN_NATION'
            when cs.rank_in_country <= cs.total_customers_in_country * 0.1 then 'TOP_10_PERCENT'
            else 'STANDARD'
        end as country_ranking,
        case
            when cs.account_balance > cs.country_average_balance then 'ABOVE_AVERAGE'
            when cs.account_balance < cs.country_average_balance then 'BELOW_AVERAGE'
            else 'AVERAGE'
        end as statistical_classification
    from customer_stats cs
    left join nations n
        on cs.nation_key = n.nation_key
)

select
    customer_key,
    customer_name,
    country,
    account_balance,
    country_average_balance,
    balance_vs_country_average,
    value_segment as customer_tier,
    market_segment,
    country_ranking,
    statistical_classification,
    round(balance_percentile * 100, 1) as balance_percentile_score,
    rank_in_country,
    case
        when value_segment = 'PREMIUM' and country_ranking = 'TOP_10_IN_NATION'
        then 'VIP Customer'
        when value_segment in ('PREMIUM', 'HIGH_VALUE')
        then 'High Value Customer'
        when statistical_classification = 'ABOVE_AVERAGE'
        then 'Above Average Customer'
        else 'Standard Customer'
    end as customer_classification,
    case
        when account_balance < 0 then 'Credit Risk'
        when value_segment = 'LOW_VALUE' then 'Retention Risk'
        when balance_vs_country_average < -1000 then 'Performance Risk'
        else 'Low Risk'
    end as risk_category,
    current_timestamp() as last_updated

from customer_base
order by account_balance desc
