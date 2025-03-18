#!/bin/busybox sh

# Construct the new variable with the required format
#ASTRO_API_URL="${ASTRO_ORGANIZATION_ID}.astronomer.run/${last_eight_deploy_id}/api/v1"
ASTRO_API_URL="$(astro deployment inspect $ASTRO_DEPLOYMENT_ID --key metadata.airflow_api_url --workspace-id $ASTRO_WORKSPACE_ID)"

echo $ASTRO_API_URL

response=$(curl -s --request GET -o response.json -w "%{http_code}" "https://$ASTRO_API_URL/dags" \
   -H 'Cache-Control: no-cache' \
   -H "Authorization: Bearer $ASTRO_API_TOKEN" || echo "curl failed")

echo "response=$response"
cat response.json | jq

#cat response.json

response=$(curl -s --request GET -o response.json -w "%{http_code}" "https://$ASTRO_API_URL/variables" \
   --header 'Cache-Control: no-cache' \
   --header "Authorization: Bearer ${ASTRO_API_TOKEN}" \
   --header "Content-Type: application/json" || echo "curl failed")

echo "response=$response"
cat response.json | jq