{{ config(
    materialized='incremental',
    unique_key='NATION_HK',
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_nations
src_pk: NATION_HK
src_hashdiff: "NATION_HASHDIFF"
src_payload:
    - "NATION_NAME"
    - "NATION_COMMENT"
    - "REGION_KEY"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
