{{ config(
    materialized='incremental',
    unique_key='NATION_HK',
    tags=['rdv', 'hub', 'tpc_h']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_nations
src_pk: NATION_HK
src_nk: NATION_KEY
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
