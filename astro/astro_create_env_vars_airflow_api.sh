#!/bin/busybox sh

# Extract the last 8 characters of $ASTRO_DEPLOYMENT_ID
last_eight_deploy_id="${ASTRO_DEPLOYMENT_ID: -8}"

# Construct the new variable with the required format
#ASTRO_API_URL="${ASTRO_ORGANIZATION_ID}.astronomer.run/${last_eight_deploy_id}/api/v1"
ASTRO_API_URL="$(astro deployment inspect $ASTRO_DEPLOYMENT_ID --key metadata.airflow_api_url --workspace-id $ASTRO_WORKSPACE_ID)"

echo $ASTRO_API_URL

cat airflow_variables.json | jq -c '.[]' | while IFS= read -r row; do
    _jq() {
        echo "${row}" | jq -r "${1}"
    }

    # Set each property of the row to a variable
    name=$(_jq '.name')
    value=$(_jq '.value')

    var_url="https://$ASTRO_API_URL/deployments/$ASTRO_DEPLOYMENT_ID/variables"

    command="curl -s --request PATCH -o response.json -w "%{http_code}" $var_url \
        --header "Authorization: Bearer ${ASTRO_API_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw '{"variables": [{"key": "'$name'", "value": "'$value'"}]}'"
    echo $command
    # Trigger request to Astronomer Airflow API
#    response=$(curl -s -o response.json -w "%{http_code}" "https://$ASTRO_API_URL/deployments/$ASTRO_DEPLOYMENT_ID/variables" \
    response=$(curl -s --request PATCH -o response.json -w "%{http_code}" "https://$ASTRO_API_URL/deployments/$ASTRO_DEPLOYMENT_ID/variables" \
        --header "Authorization: Bearer ${ASTRO_API_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw '{"variables": [{"key": "'$name'", "value": "'$value'"}]}' || echo "curl failed")

    cat response.json

    # Check if the response contains "error"
    if [ "$response" -lt 200 ] || [ "$response" -gt 299 ]; then
        echo "Error: Non-successful HTTP status code $response received."
        api_call_failed=true
    elif [ "$response" = "curl failed"]; then
        echo "Error: cURL request failed."
        api_call_failed=true
    else
        echo "Request successful with status code $response."
    fi
done

if [ api_call_failed=true ]; then
    echo "Failed"
fi