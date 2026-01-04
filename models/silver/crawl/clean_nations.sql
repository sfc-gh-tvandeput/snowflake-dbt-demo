{{ config(
    materialized='incremental',
    unique_key='nation_key',
    incremental_strategy='merge',
    tags=['silver', 'crawl', 'cleaned_data', 'incremental'],
    static_analysis='unsafe'
) }}

-- SILVER CRAWL: Incremental data cleaning with AI classification
-- Complexity: Intermediate - Incremental loading, AI functions, efficiency optimization
-- Features demonstrated: Incremental materialization, AI classification, performance optimization

select
    nation_key,
    upper(trim(nation_name)) as nation_name,
    region_key,
    trim(nation_comment) as nation_comment,

    -- Basic derived fields
    length(nation_name) as name_length,
    -- TODO: dbt Fusion static analysis blocks Cortex functions at compile time
    -- Uncomment when dbt Fusion supports SNOWFLAKE.CORTEX functions
    -- snowflake.cortex.classify_text(
    --     nation_name,
    --     ['FEDERAL', 'REPUBLIC', 'KINGDOM', 'EMPIRE', 'CONFEDERATION', 'UNION', 'FEDERATION', 'PRINCIPALITY', 'DUCHY', 'SULTANATE', 'EMIRATE', 'OTHER']
    -- ):label as government_type,
    'OTHER' as government_type,

    current_timestamp() as processed_at

from {{ ref('stg_tpc_h__nations') }}

{%- if is_incremental() %}
  -- Only process records that don't exist or have been updated
  where nation_key not in (
    select nation_key from {{ this }}
  )
{%- endif %}
