{{ config(
    materialized='incremental',
    unique_key=['CUSTOMER_HK', 'LOAD_DATE'],
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{#-
    Raw Data Vault Satellite: SAT_CUSTOMER

    Contains descriptive attributes for customers with full history
    Parent Hub: HUB_CUSTOMER
    Loaded from: stg_dv_customers

    Tracks changes via: CUSTOMER_HASHDIFF
    Payload: Customer name, address, phone, account balance, market segment, comment
-#}

{%- set yaml_metadata -%}
source_model: stg_dv_customers
src_pk: CUSTOMER_HK
src_hashdiff:
    source_column: "CUSTOMER_HASHDIFF"
    alias: "HASHDIFF"
src_payload:
    - "CUSTOMER_NAME"
    - "CUSTOMER_ADDRESS"
    - "NATION_KEY"
    - "CUSTOMER_PHONE"
    - "ACCOUNT_BALANCE"
    - "MARKET_SEGMENT"
    - "CUSTOMER_COMMENT"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
