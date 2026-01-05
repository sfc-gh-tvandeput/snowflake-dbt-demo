{{ config(
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "REGION"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "CURRENT_TIMESTAMP()"
    REGION_KEY: "R_REGIONKEY"
    REGION_NAME: "R_NAME"
    REGION_COMMENT: "R_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    REGION_HK: "R_REGIONKEY"
    REGION_HASHDIFF:
        is_hashdiff: true
        columns:
            - "R_NAME"
            - "R_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
