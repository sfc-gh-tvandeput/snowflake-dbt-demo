{{ config(
    materialized='incremental',
    unique_key='PART_HK',
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_parts
src_pk: PART_HK
src_hashdiff: "PART_HASHDIFF"
src_payload:
    - "PART_NAME"
    - "MANUFACTURER"
    - "BRAND"
    - "PART_TYPE"
    - "PART_SIZE"
    - "CONTAINER"
    - "RETAIL_PRICE"
    - "PART_COMMENT"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
