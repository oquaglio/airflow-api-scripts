#!/bin/bash

# Export necessary environment variables
MWAA_ENV_NAME=$MWAA_ENV_NAME
MWAA_API_URL=$(aws mwaa get-environment --name "$MWAA_ENV_NAME" --query "Environment.WebserverUrl" --output text | sed 's/\/$//')
MWAA_AUTH_TOKEN=$(aws mwaa create-web-login-token --name "$MWAA_ENV_NAME" --query "WebToken" --output text)

if [ -z "$MWAA_API_URL" ] || [ -z "$MWAA_AUTH_TOKEN" ]; then
    echo "Error: Could not retrieve MWAA environment information."
    exit 1
fi

echo "MWAA Airflow API URL: $MWAA_API_URL"

# Base URL for DAGs
request_url="$MWAA_API_URL/api/v1/dags"

# Fetch the list of DAGs
command="curl -s --request GET -o dags_response.json -w '%{http_code}' \"$request_url\" \
    --header \"Authorization: Bearer $MWAA_AUTH_TOKEN\" \
    --header \"Content-Type: application/json\""

echo "Running command:"
echo "$command" | sed 's/Bearer [^\"]*/Bearer [TOKEN REDACTED]/'

response=$(eval "$command" || echo "curl failed")

echo "Response Status Code: $response"

# Check if the response is successful
if [ "$response" -lt 200 ] || [ "$response" -gt 299 ]; then
    echo "Error: Non-successful HTTP status code $response received"
    exit 1
elif [ "$response" = "curl failed" ]; then
    echo "Error: cURL request failed"
    exit 1
fi

# Parse and process DAG information
if ! command -v jq > /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi
echo "Parsing DAG information..."

echo "dag_id,dag_display_name,path,is_active,is_paused,has_import_errors" > dag_details.csv

jq -r '.dags[] | [.dag_id, .dag_id, .fileloc, .is_active, .is_paused, .has_import_errors] | @csv' dags_response.json >> dag_details.csv

echo "DAG details have been written to dag_details.csv."
