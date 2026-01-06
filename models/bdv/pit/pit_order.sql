{{ config(
    materialized='pit_incremental',
    tags=['bdv', 'pit', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: hub_order
src_pk: ORDER_HK
as_of_dates_table: as_of_date
satellites:
    sat_order:
        pk:
            PK: ORDER_HK
        ldts:
            LDTS: LOAD_DATE
stage_tables_ldts:
    stg_dv_orders: LOAD_DATE
src_ldts: LOAD_DATE
{%- endset -%}

{{ automate_dv.pit(**fromyaml(yaml_metadata)) }}
