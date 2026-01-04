{{ config(
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{#-
    Data Vault Staging Model for TPC-H ORDERS source
    Refactored to use AutomateDV stage() macro

    This model adds:
    - Hashed business keys (order_hk, customer_hk)
    - Hash diff for change tracking (order_hashdiff)
    - Data Vault metadata (load_date, record_source)
    - Maintains backward compatibility with existing column names
-#}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "ORDERS"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "CURRENT_TIMESTAMP()"
    ORDER_KEY: "O_ORDERKEY"
    CUSTOMER_KEY: "O_CUSTKEY"
    ORDER_STATUS: "O_ORDERSTATUS"
    TOTAL_PRICE: "O_TOTALPRICE"
    ORDER_DATE: "O_ORDERDATE"
    ORDER_PRIORITY: "O_ORDERPRIORITY"
    CLERK: "O_CLERK"
    SHIP_PRIORITY: "O_SHIPPRIORITY"
    ORDER_COMMENT: "O_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    ORDER_HK: "O_ORDERKEY"
    CUSTOMER_HK: "O_CUSTKEY"
    CUSTOMER_ORDER_HK:
        - "O_CUSTKEY"
        - "O_ORDERKEY"
    ORDER_HASHDIFF:
        is_hashdiff: true
        columns:
            - "O_CUSTKEY"
            - "O_ORDERSTATUS"
            - "O_TOTALPRICE"
            - "O_ORDERDATE"
            - "O_ORDERPRIORITY"
            - "O_CLERK"
            - "O_SHIPPRIORITY"
            - "O_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
