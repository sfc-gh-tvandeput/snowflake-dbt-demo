{{ config(
    tags=['staging', 'tpc_h', 'data_vault']
) }}

{#-
    Data Vault Staging Model for TPC-H NATION source
    Refactored to use AutomateDV stage() macro

    This model adds:
    - Hashed business keys (nation_hk)
    - Hash diff for change tracking (nation_hashdiff)
    - Data Vault metadata (load_date, record_source)
    - Maintains backward compatibility with existing column names
-#}

{%- set yaml_metadata -%}
source_model:
    TPC_H: "NATION"

derived_columns:
    RECORD_SOURCE: "!TPC_H"
    LOAD_DATE: "CURRENT_TIMESTAMP()"
    NATION_KEY: "N_NATIONKEY"
    REGION_KEY: "N_REGIONKEY"
    NATION_NAME: "N_NAME"
    NATION_COMMENT: "N_COMMENT"
    _LOADED_AT: "CURRENT_TIMESTAMP()"

hashed_columns:
    NATION_HK: "N_NATIONKEY"
    REGION_HK: "N_REGIONKEY"
    NATION_HASHDIFF:
        is_hashdiff: true
        columns:
            - "N_NAME"
            - "N_REGIONKEY"
            - "N_COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(include_source_columns=true,
                      source_model=metadata_dict['source_model'],
                      derived_columns=metadata_dict['derived_columns'],
                      hashed_columns=metadata_dict['hashed_columns'],
                      ranked_columns=none) }}
