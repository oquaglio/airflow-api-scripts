#!/bin/busybox sh

# https://www.astronomer.io/docs/api/overview

#ASTRO_API_URL="${ASTRO_ORGANIZATION_ID}.astronomer.run/${last_eight_deploy_id}/api/v1"
ASTRO_API_URL="$(astro deployment inspect $ASTRO_DEPLOYMENT_ID --key metadata.airflow_api_url --workspace-id $ASTRO_WORKSPACE_ID)"

echo $ASTRO_API_URL

# select your request:
#request_url="https://$ASTRO_API_URL/plugins"
#request_url="https://$ASTRO_API_URL/pools"
#request_url="https://$ASTRO_API_URL/providers"
#request_url="https://$ASTRO_API_URL/dagStats?dag_ids=get_env_info,run_bash_cmd"
request_url="https://$ASTRO_API_URL/variables" # get Airflow variables (Airflow UI)

command="curl -s --request GET -o response.json -w \"%{http_code}\" \"$request_url\" \
    --header \"Authorization: Bearer ${ASTRO_API_TOKEN}\" \
    --header \"Content-Type: application/json\""

echo "Running command:"
echo "$command" | sed 's/Bearer [^"]*/Bearer [TOKEN REDACTED]/'

response=$(eval "$command" || echo "curl failed")

echo "Response Status Code: $response"

echo "Response JSON:"
cat response.json

# Check if the response contains "error"
if [ "$response" -lt 200 ] || [ "$response" -gt 299 ]; then
    echo "Error: Non-successful HTTP status code $response received"
    api_call_failed=true
elif [ "$response" = "curl failed" ]; then
    echo "Error: cURL request failed"
    api_call_failed=true
else
    echo "Request was successful"
fi

if [ api_call_failed=true ]; then
    exit 1
fi