#!/bin/bash

echo $GITHUB_EVENT_PATH
cat $GITHUB_EVENT_PATH

COLUMN_URL=$(jq -r '.project_card.column_url' "$GITHUB_EVENT_PATH")/files
echo "Project link = $PROJECT_URL"

curl $COLUMN_URL > column.json

cat column.json

COLUMN_NAME=`jq -r '.name' column.json`

echo "Column name: $COLUMN_NAME"

if ["$COLUMN_NAME" = "Ready to test"]; then
    	echo "No updates. $COLUMN_NAME"
	exit 0
fi

echo "Performing checkup:"

#OUTPUT=$'**CLANG WARNINGS**:\n'
#OUTPUT+=$'\n```\n'
#OUTPUT+="$PAYLOAD_CLANG"
#OUTPUT+=$'\n```\n'

#OUTPUT+=$'\n**CPPCHECK WARNINGS**:\n'
#OUTPUT+=$'\n```\n'
#OUTPUT+="$PAYLOAD_CPPCHECK"
#OUTPUT+=$'\n```\n' 

#PAYLOAD=$(echo '{}' | jq --arg body "$OUTPUT" '.body = $body')

#curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/vnd.github.VERSION.text+json" --data "$PAYLOAD" "$COMMENTS_URL"
