#!/bin/busybox sh

# https://www.astronomer.io/docs/astro/cli/astro-deployment-variable-create/
# https://www.astronomer.io/docs/astro/cli/astro-deployment-variable-update

# Construct the new variable with the required format
#ASTRO_API_URL="${ASTRO_ORGANIZATION_ID}.astronomer.run/${last_eight_deploy_id}/api/v1"
ASTRO_API_URL="$(astro deployment inspect $ASTRO_DEPLOYMENT_ID --key metadata.airflow_api_url --workspace-id $ASTRO_WORKSPACE_ID)"

echo $ASTRO_API_URL

#astro deployment variable list --deployment-id $ASTRO_DEPLOYMENT_ID

cat airflow_variables.json | jq -c '.[]' | while IFS= read -r row; do
    _jq() {
        echo "${row}" | jq -r "${1}"
    }

    # Set each property of the row to a variable
    name=$(_jq '.name')
    value=$(_jq '.value')

    #echo "Setting $name=$value..."
    #command="astro deployment variable create $name='$value' --deployment-id $ASTRO_DEPLOYMENT_ID"
    command="astro deployment variable update $name='$value' --deployment-id $ASTRO_DEPLOYMENT_ID"
    echo "Executing command: '$command'..."
    set +e # so we can catch the response if error
    output=$(eval "$command 2>&1")
    command_status=$?
    set -e
    if [ $command_status -eq 0 ]; then
        echo "Command executed successfully. Response from Astro CLI:"
        echo "$output"
    else
        echo "command_status=$command_status"
        echo "Failed to execute command. Response from Astro CLI:"
        echo "$output"
    fi
    echo "Created $name successfully"

done

