#!/bin/bash

# set environment variables
ENVIRONMENT_VARIABLES_FILEPATH='workflows/.env'
source $ENVIRONMENT_VARIABLES_FILEPATH

# unlock
sqlite3 $LOCAL_PROCESSED_DATABASE_FILEPATH '.clone chat-new.db'
mv $LOCAL_PROCESSED_DATABASE_FILEPATH chat-old.db
mv chat-new.db $LOCAL_PROCESSED_DATABASE_FILEPATH
rm chat-old.db
