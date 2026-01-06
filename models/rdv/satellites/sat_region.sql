{{ config(
    materialized='incremental',
    unique_key='REGION_HK',
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_regions
src_pk: REGION_HK
src_hashdiff: "REGION_HASHDIFF"
src_payload:
    - "REGION_NAME"
    - "REGION_COMMENT"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
