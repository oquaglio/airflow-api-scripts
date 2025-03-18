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

# Parse DAG IDs
if ! command -v jq > /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi
echo "Parsing DAG IDs..."
dag_ids=$(jq -r '.dags[] | .dag_id' dags_response.json)

echo "DAG IDs found:"
echo "$dag_ids"

# Output CSV Header
echo "dag_id,dag_display_name,path,is_active,is_paused,has_import_errors" > dag_details.csv

# Iterate over each DAG and fetch its properties
for dag_id in $dag_ids; do
    dag_detail_url="https://$ASTRO_API_URL/dags/$dag_id"

    command="curl -s --request GET \"$dag_detail_url\" \
        --header \"Authorization: Bearer ${ASTRO_API_TOKEN}\" \
        --header \"Content-Type: application/json\""

    response=$(eval "$command" || echo "curl failed")

    if [ "$response" = "curl failed" ]; then
        echo "Error: Failed to fetch details for DAG $dag_id"
        continue
    fi

    # Extract properties
    dag_display_name=$(echo "$response" | jq -r '.dag_id')
    path=$(echo "$response" | jq -r '.fileloc')
    is_active=$(echo "$response" | jq -r '.is_active')
    is_paused=$(echo "$response" | jq -r '.is_paused')
    has_import_errors=$(echo "$response" | jq -r '.has_import_errors')

    # Append to CSV
    echo "$dag_id,$dag_display_name,$path,$is_active,$is_paused,$has_import_errors" >> dag_details.csv

done

echo "DAG details have been written to dag_details.csv."
