#!/bin/bash

# Export necessary environment variables
MWAA_ENV_NAME=$MWAA_ENV_NAME

# Get list of DAGs directly using AWS CLI
aws mwaa list-dags --name "$MWAA_ENV_NAME" --query "dags[].{dag_id:dag_id,dag_display_name:dag_id,fileloc:fileloc,is_active:is_active,is_paused:is_paused,has_import_errors:has_import_errors}" --output json > dags_response.json

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve DAGs using AWS CLI."
    exit 1
fi

# Parse and process DAG information
if ! command -v jq > /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi
echo "Parsing DAG information..."

echo "dag_id,dag_display_name,path,is_active,is_paused,has_import_errors" > dag_details.csv

jq -r '.[] | [.dag_id, .dag_display_name, .fileloc, .is_active, .is_paused, .has_import_errors] | @csv' dags_response.json >> dag_details.csv

echo "DAG details have been written to dag_details.csv."
