#!/bin/busybox sh

# Fetch the Airflow API URL
ASTRO_API_URL=$(astro deployment inspect $ASTRO_DEPLOYMENT_ID --key metadata.airflow_api_url --workspace-id $ASTRO_WORKSPACE_ID)

echo "Airflow API URL: $ASTRO_API_URL"

# Base URL for DAGs
request_url="https://$ASTRO_API_URL/dags"

# Fetch the list of DAGs
command="curl -s --request GET -o dags_response.json -w '%{http_code}' \"$request_url\" \
    --header \"Authorization: Bearer ${ASTRO_API_TOKEN}\" \
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
