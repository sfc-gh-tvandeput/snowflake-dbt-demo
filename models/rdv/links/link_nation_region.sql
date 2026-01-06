{{ config(
    materialized='incremental',
    unique_key='NATION_REGION_HK',
    tags=['rdv', 'link', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_nations
src_pk: NATION_REGION_HK
src_fk:
    - "NATION_HK"
    - "REGION_HK"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.link(**fromyaml(yaml_metadata)) }}
