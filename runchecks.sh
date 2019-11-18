#!/bin/bash

cat $GITHUB_EVENT_PATH

COLUMN_URL=$(jq -r '.project_card.column_url' "$GITHUB_EVENT_PATH")
echo "Column link = $PROJECT_URL"

curl $COLUMN_URL > column.json

cat column.json

COLUMN_NAME=`jq -r '.name' column.json`

echo "Column name: $COLUMN_NAME"

if ["$COLUMN_NAME" = "Ready to test"]; then
    	echo "No updates. $COLUMN_NAME"
	exit 0
fi

echo "Performing checkup:"