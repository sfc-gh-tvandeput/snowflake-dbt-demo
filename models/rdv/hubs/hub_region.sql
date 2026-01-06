{{ config(
    materialized='incremental',
    unique_key='REGION_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_regions
src_pk: REGION_HK
src_nk: REGION_KEY
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
