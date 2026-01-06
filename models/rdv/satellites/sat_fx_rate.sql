{{ config(
    materialized='incremental',
    unique_key='FX_RATE_HK',
    tags=['rdv', 'satellite', 'economic']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_fx_rates
src_pk: FX_RATE_HK
src_hashdiff: "FX_RATE_HASHDIFF"
src_payload:
    - "RATE_DATE"
    - "EXCHANGE_RATE"
    - "VARIABLE_ID"
    - "VARIABLE_NAME"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
