{{ config(
    tags=['staging', 'economic_essentials', 'data_vault']
) }}

{%- set yaml_metadata -%}
source_model:
    ECONOMIC_ESSENTIALS: "FX_RATES_TIMESERIES"

derived_columns:
    RECORD_SOURCE: "!CYBERSYN"
    LOAD_DATE: "CURRENT_TIMESTAMP()"
    RATE_DATE: "DATE"
    BASE_CURRENCY: "BASE_CURRENCY_ID"
    QUOTE_CURRENCY: "QUOTE_CURRENCY_ID"
    EXCHANGE_RATE: "VALUE"
    VARIABLE_ID: "VARIABLE"
    VARIABLE_NAME: "VARIABLE_NAME"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    CURRENCY_PAIR_HK:
        - "BASE_CURRENCY_ID"
        - "QUOTE_CURRENCY_ID"
    FX_RATE_HK:
        - "BASE_CURRENCY_ID"
        - "QUOTE_CURRENCY_ID"
        - "DATE"
    FX_RATE_HASHDIFF:
        is_hashdiff: true
        columns:
            - "VALUE"
            - "VARIABLE"
            - "VARIABLE_NAME"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
