#!/bin/busybox sh

#https://www.astronomer.io/docs/astro/cli/astro-deployment-airflow-variable-create

# Creates an Airflow Variable in a Deployment in the Airflow UI (in Airflow Metadatabase)
# Will also update an existing Variable

cat airflow_variables.json | jq -c '.[]' | while IFS= read -r row; do
    _jq() {
        echo "${row}" | jq -r "${1}"
    }

    # Set each property of the row to a variable
    name=$(_jq '.name')
    value=$(_jq '.value')

    command="astro deployment airflow-variable create --key $name --value '$value' --deployment-id $ASTRO_DEPLOYMENT_ID"
    echo "Executing command: '$command'..."
    set +e # so we can catch the response if error
    output=$(eval "$command 2>&1")
    command_status=$?
    set -e
    echo "command_status=$command_status"
    if [ $command_status -eq 0 ]; then
        echo "Command executed successfully. Response from Astro CLI:"
        echo "$output"
    else
        echo "Failed to execute command. Response from Astro CLI:"
        echo "$output"
        exit 1
    fi
done

