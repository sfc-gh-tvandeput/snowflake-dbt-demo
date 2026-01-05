{{ config(
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "SUPPLIER"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "DATE('1992-01-01')"
    SUPPLIER_KEY: "S_SUPPKEY"
    SUPPLIER_NAME: "S_NAME"
    SUPPLIER_ADDRESS: "S_ADDRESS"
    NATION_KEY: "S_NATIONKEY"
    SUPPLIER_PHONE: "S_PHONE"
    ACCOUNT_BALANCE: "S_ACCTBAL"
    SUPPLIER_COMMENT: "S_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    SUPPLIER_HK: "S_SUPPKEY"
    NATION_HK: "S_NATIONKEY"
    SUPPLIER_NATION_HK:
        - "S_SUPPKEY"
        - "S_NATIONKEY"
    SUPPLIER_HASHDIFF:
        is_hashdiff: true
        columns:
            - "S_NAME"
            - "S_ADDRESS"
            - "S_NATIONKEY"
            - "S_PHONE"
            - "S_ACCTBAL"
            - "S_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
