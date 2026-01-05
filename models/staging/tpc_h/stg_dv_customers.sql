{{ config(
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "CUSTOMER"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "DATE('1992-01-01')"
    CUSTOMER_KEY: "C_CUSTKEY"
    CUSTOMER_NAME: "C_NAME"
    CUSTOMER_ADDRESS: "C_ADDRESS"
    NATION_KEY: "C_NATIONKEY"
    CUSTOMER_PHONE: "C_PHONE"
    ACCOUNT_BALANCE: "C_ACCTBAL"
    MARKET_SEGMENT: "C_MKTSEGMENT"
    CUSTOMER_COMMENT: "C_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    CUSTOMER_HK: "C_CUSTKEY"
    NATION_HK: "C_NATIONKEY"
    CUSTOMER_NATION_HK:
        - "C_CUSTKEY"
        - "C_NATIONKEY"
    CUSTOMER_HASHDIFF:
        is_hashdiff: true
        columns:
            - "C_NAME"
            - "C_ADDRESS"
            - "C_NATIONKEY"
            - "C_PHONE"
            - "C_ACCTBAL"
            - "C_MKTSEGMENT"
            - "C_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
