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
PULLS_ROOT_URL=$(jq -r '.repository.pulls_url' "$GITHUB_EVENT_PATH")
PULLS_ROOT_URL=${PULLS_ROOT_URL%\{/number\}}

echo "Pulls url: $PULLS_ROOT_URL"
curl -s -S -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json $PULLS?state=open" $PULLS_ROOT_URL > pulls_data.json

echo "Pulls info:"
cat pulls_data.json

CARD_NOTE=$(jq -r '.project_card.note' "$GITHUB_EVENT_PATH")
TASK_NUMBER=$(echo $CARD_NOTE | grep -oPe "(task.|lab.)\K\d+")
CARD_ID=$(jq -r '.project_card.id' "$GITHUB_EVENT_PATH")

echo -e "Task number = $TASK_NUMBER;\nCard note: $CARD_NOTE;\nCard id: $CARD_ID\n"

jq -r ".[] | select (.title | contains(\"$CARD_ID\")) | .url" pulls_data.json > pulls

echo "Pulls to be checked:"
cat pulls

function processPullRequest() {
  PR_ID=$(echo $1 | grep -oP -e '\d.$')
  echo "Processing pull request with id $PR_ID"
}

< pulls | while read pr_link; do
  processPullRequest pr_link
done
