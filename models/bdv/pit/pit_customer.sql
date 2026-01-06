{{ config(
    materialized='pit_incremental',
    tags=['bdv', 'pit', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: hub_customer
src_pk: CUSTOMER_HK
as_of_dates_table: as_of_date
satellites:
    sat_customer:
        pk:
            PK: CUSTOMER_HK
        ldts:
            LDTS: LOAD_DATE
stage_tables_ldts:
    stg_dv_customers: LOAD_DATE
src_ldts: LOAD_DATE
{%- endset -%}

{{ automate_dv.pit(**fromyaml(yaml_metadata)) }}
