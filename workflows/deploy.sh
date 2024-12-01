#!/bin/bash

# set environment variables
ENVIRONMENT_VARIABLES_FILEPATH='workflows/.env'
source $ENVIRONMENT_VARIABLES_FILEPATH

# preprocess database
python -m src.main process_database -c \
    -k workflows/process_database.yaml "{\"database_destination_filepath\": \"${LOCAL_PROCESSED_DATABASE_FILEPATH}\"}" \
        || exit 1

# copy database to Grafana server
echo
echo "Copying database to Grafana server ..."
scp $LOCAL_PROCESSED_DATABASE_FILEPATH $GRAFANA_SERVER_USERNAME@$GRAFANA_SERVER_IP_ADDRESS:$GRAFANA_SERVER_DATABASE_FILEPATH