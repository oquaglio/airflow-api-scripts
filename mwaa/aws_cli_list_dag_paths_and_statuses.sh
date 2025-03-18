#!/bin/bash

# Export necessary environment variables
MWAA_ENV_NAME=$MWAA_ENV_NAME
AWS_REGION=$AWS_REGION

# Get MWAA CLI token and Webserver hostname
CLI_JSON=$(aws mwaa --region "$AWS_REGION" create-cli-token --name "$MWAA_ENV_NAME")
CLI_TOKEN=$(echo $CLI_JSON | jq -r '.CliToken')
WEB_SERVER_HOSTNAME=$(echo $CLI_JSON | jq -r '.WebServerHostname')

if [ -z "$CLI_TOKEN" ] || [ -z "$WEB_SERVER_HOSTNAME" ]; then
    echo "Error: Could not retrieve MWAA CLI token or Webserver hostname."
    exit 1
fi

echo "MWAA Webserver Hostname: $WEB_SERVER_HOSTNAME"

# Fetch DAG details using MWAA CLI token
CLI_RESULTS=$(curl -s --request POST "https://$WEB_SERVER_HOSTNAME/aws_mwaa/cli" \
    --header "Authorization: Bearer $CLI_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{"cmd":"dags list --output json"}')

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve DAG details using MWAA CLI."
    exit 1
fi

# Parse and process DAG information
if ! command -v jq > /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi
echo "Parsing DAG information..."

echo "dag_id,dag_display_name,path,is_active,is_paused,has_import_errors" > dag_details.csv

echo "$CLI_RESULTS" | jq -r '.dags[] | [.dag_id, .dag_id, .fileloc, .is_active, .is_paused, .has_import_errors] | @csv' >> dag_details.csv

echo "DAG details have been written to dag_details.csv."
