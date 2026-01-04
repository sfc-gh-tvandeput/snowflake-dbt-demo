{{ config(
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{#-
    Data Vault Staging Model for TPC-H LINEITEM source
    Refactored to use AutomateDV stage() macro

    This model adds:
    - Hashed business keys (lineitem_hk, order_hk, part_hk, supplier_hk)
    - Composite hash key for composite primary key
    - Hash diff for change tracking (lineitem_hashdiff)
    - Data Vault metadata (load_date, record_source)
    - Maintains backward compatibility with existing column names
-#}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "LINEITEM"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "CURRENT_TIMESTAMP()"
    ORDER_KEY: "L_ORDERKEY"
    LINE_NUMBER: "L_LINENUMBER"
    PART_KEY: "L_PARTKEY"
    SUPPLIER_KEY: "L_SUPPKEY"
    QUANTITY: "L_QUANTITY"
    EXTENDED_PRICE: "L_EXTENDEDPRICE"
    DISCOUNT: "L_DISCOUNT"
    TAX: "L_TAX"
    RETURN_FLAG: "L_RETURNFLAG"
    LINE_STATUS: "L_LINESTATUS"
    SHIP_DATE: "L_SHIPDATE"
    COMMIT_DATE: "L_COMMITDATE"
    RECEIPT_DATE: "L_RECEIPTDATE"
    SHIP_INSTRUCT: "L_SHIPINSTRUCT"
    SHIP_MODE: "L_SHIPMODE"
    LINE_COMMENT: "L_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    LINEITEM_HK:
        - "L_ORDERKEY"
        - "L_LINENUMBER"
    ORDER_HK: "L_ORDERKEY"
    PART_HK: "L_PARTKEY"
    SUPPLIER_HK: "L_SUPPKEY"
    LINEITEM_ORDER_HK:
        - "L_ORDERKEY"
        - "L_LINENUMBER"
    LINEITEM_HASHDIFF:
        is_hashdiff: true
        columns:
            - "L_PARTKEY"
            - "L_SUPPKEY"
            - "L_QUANTITY"
            - "L_EXTENDEDPRICE"
            - "L_DISCOUNT"
            - "L_TAX"
            - "L_RETURNFLAG"
            - "L_LINESTATUS"
            - "L_SHIPDATE"
            - "L_COMMITDATE"
            - "L_RECEIPTDATE"
            - "L_SHIPINSTRUCT"
            - "L_SHIPMODE"
            - "L_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
