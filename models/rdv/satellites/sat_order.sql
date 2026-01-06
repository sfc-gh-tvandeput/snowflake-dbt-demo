{{ config(
    materialized='incremental',
    unique_key=['ORDER_HK', 'LOAD_DATE'],
    tags=['rdv', 'satellite', 'tpc_h']
) }}

{#-
    Raw Data Vault Satellite: SAT_ORDER

    Contains descriptive attributes for orders with full history
    Parent Hub: HUB_ORDER
    Loaded from: stg_dv_orders

    Tracks changes via: ORDER_HASHDIFF
    Payload: Customer key, order status, price, date, priority, clerk, ship priority, comment
-#}

{%- set yaml_metadata -%}
source_model: stg_dv_orders
src_pk: ORDER_HK
src_hashdiff:
    source_column: "ORDER_HASHDIFF"
    alias: "HASHDIFF"
src_payload:
    - "CUSTOMER_KEY"
    - "ORDER_STATUS"
    - "TOTAL_PRICE"
    - "ORDER_DATE"
    - "ORDER_PRIORITY"
    - "CLERK"
    - "SHIP_PRIORITY"
    - "ORDER_COMMENT"
src_eff: "LOAD_DATE"
src_ldts: LOAD_DATE
src_source: RECORD_SOURCE
{%- endset -%}



{{ automate_dv.sat(**fromyaml(yaml_metadata)) }}
