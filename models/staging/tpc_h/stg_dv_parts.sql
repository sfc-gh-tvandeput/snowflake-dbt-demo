{{ config(
    materialized='ephemeral',
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "PART"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "DATE('1992-01-01')"
    PART_KEY: "P_PARTKEY"
    PART_NAME: "P_NAME"
    MANUFACTURER: "P_MFGR"
    BRAND: "P_BRAND"
    PART_TYPE: "P_TYPE"
    PART_SIZE: "P_SIZE"
    CONTAINER: "P_CONTAINER"
    RETAIL_PRICE: "P_RETAILPRICE"
    PART_COMMENT: "P_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    PART_HK: "P_PARTKEY"
    PART_HASHDIFF:
        is_hashdiff: true
        columns:
            - "P_NAME"
            - "P_MFGR"
            - "P_BRAND"
            - "P_TYPE"
            - "P_SIZE"
            - "P_CONTAINER"
            - "P_RETAILPRICE"
            - "P_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
