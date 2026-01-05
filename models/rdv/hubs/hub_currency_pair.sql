{{ config(
    materialized='incremental',
    unique_key='CURRENCY_PAIR_HK',
    tags=['rdv', 'hub', 'economic']
) }}

{#-
    Raw Data Vault Hub: HUB_CURRENCY_PAIR

    Pattern: Hub (Unique business keys only)
    Grain: One row per unique currency pair (BASE_CURRENCY + QUOTE_CURRENCY)
    Source: Cybersyn FX_RATES_TIMESERIES via stg_dv_fx_rates
-#}

{%- set yaml_metadata -%}
source_model: "stg_dv_fx_rates"
src_pk: "CURRENCY_PAIR_HK"
src_nk:
    - "BASE_CURRENCY"
    - "QUOTE_CURRENCY"
src_ldts: "LOAD_DATE"
src_source: "RECORD_SOURCE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict['src_pk'],
                    src_nk=metadata_dict['src_nk'],
                    src_ldts=metadata_dict['src_ldts'],
                    src_source=metadata_dict['src_source'],
                    source_model=metadata_dict['source_model']) }}
