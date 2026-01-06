{{ config(
    materialized='pit_incremental',
    tags=['bdv', 'pit', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: hub_product
src_pk: PART_HK
as_of_dates_table: as_of_date
satellites:
    sat_product:
        pk:
            PK: PART_HK
        ldts:
            LDTS: LOAD_DATE
stage_tables_ldts:
    stg_dv_parts: LOAD_DATE
src_ldts: LOAD_DATE
{%- endset -%}

{{ automate_dv.pit(**fromyaml(yaml_metadata)) }}
