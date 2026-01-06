{{ config(
    materialized='incremental',
    unique_key='CURRENCY_PAIR_HK',
    tags=['rdv', 'hub', 'economic']
) }}

{%- set yaml_metadata -%}
source_model: stg_dv_fx_rates
src_pk: CURRENCY_PAIR_HK
src_nk:
    - "BASE_CURRENCY"
    - "QUOTE_CURRENCY"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.hub(**fromyaml(yaml_metadata)) }}
