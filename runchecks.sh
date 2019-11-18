#!/bin/bash
if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "The GITHUB_TOKEN is required."
	exit 1
fi

cat $GITHUB_EVENT_PATH

COLUMN_URL=$(jq -r '.project_card.column_url' "$GITHUB_EVENT_PATH")
echo "Column link = $COLUMN_URL"

curl -s -S -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.inertia-preview+json" $COLUMN_URL > column.json

echo "Column info:"
cat column.json

COLUMN_NAME=$(jq -r '.name' column.json)

echo "Column name: $COLUMN_NAME"

if [[ "$COLUMN_NAME" != "Ready to test" ]]; then
    	echo "No updates. $COLUMN_NAME"
	exit 0
fi

echo "Performing checkup:"