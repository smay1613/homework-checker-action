#!/bin/bash
if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "The GITHUB_TOKEN is required."
	exit 1
fi

function debug() {
  if [[ -n "$DEBUG" ]]; then
     echo "[DEBUG] $*"
  fi
}

debug $(cat $GITHUB_EVENT_PATH)

COLUMN_URL=$(jq -r '.project_card.column_url' "$GITHUB_EVENT_PATH")
debug $(echo "Column link = $COLUMN_URL")

curl -s -S -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.inertia-preview+json" $COLUMN_URL > column.json

debug $(echo "Column info:" && cat column.json)

COLUMN_NAME=$(jq -r '.name' column.json)

debug $(echo "Column name: $COLUMN_NAME")

if [[ "$COLUMN_NAME" != "Ready to test" ]]; then
    	echo "No updates. $COLUMN_NAME"
	exit 0
fi

echo "Performing checkup:"
PULLS_ROOT_URL=$(jq -r '.repository.pulls_url' "$GITHUB_EVENT_PATH")
PULLS_ROOT_URL=${PULLS_ROOT_URL%\{/number\}}

debug $(echo "Pulls url: $PULLS_ROOT_URL")
curl -s -S -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json $PULLS?state=open" $PULLS_ROOT_URL > pulls_data.json

debug $(echo "Pulls info:" && cat pulls_data.json)

CARD_NOTE=$(jq -r '.project_card.note' "$GITHUB_EVENT_PATH")
TASK_NUMBER=$(echo $CARD_NOTE | grep -oPe "(task.|lab.)\K\d+")
CARD_ID=$(jq -r '.project_card.id' "$GITHUB_EVENT_PATH")

debug $(echo -e "Task number = $TASK_NUMBER;\nCard note: $CARD_NOTE;\nCard id: $CARD_ID\n")

jq -r ".[] | select (.title | contains(\"$CARD_ID\")) | .url" pulls_data.json > pulls

debug $(echo "Pulls to be checked:" && cat pulls)

REPO_URL=$(jq -r '.repository.url' "$GITHUB_EVENT_PATH")

debug $(echo "Repo URL: $REPO_URL")

TESTS_DIR="$GITHUB_WORKSPACE/tests"
LAB_TESTS_DIR="$TESTS_DIR/Lab$TASK_NUMBER"
debug $(echo "Tests dir: $TESTS_DIR" && ls $TESTS_DIR)
debug $(echo "Lab dir: $LAB_TESTS_DIR" && ls $LAB_TESTS_DIR)

function prepareRepo() {
  rm -r $1/src  
  rm -r $1/include
  rm $1/CMakeLists.txt
  cp -l CMakeLists.txt $1
  cp -rl src $1
  cp -rl include $1
}

chmod +x $TESTS_DIR/run-tests.sh

function processPullRequest() {
  PR_ID=$(echo $1 | grep -oP -e 'pulls\/\K\d+$')
  debug $(echo "Processing pull request with id $PR_ID")
  ARCHIVE_URL="$REPO_URL/zipball/pull/$PR_ID/head"
  curl -s -L $ARCHIVE_URL --output "$PR_ID.zip" && debug $(echo "Downloaded successfully") || (echo "Cannot download!" && exit 1)
  unzip $PR_ID.zip -d $PR_ID
  cd $PR_ID && cd $(ls)
  debug $(ls)
  prepareRepo $LAB_TESTS_DIR
  export COMMENTS_URL="${1/pulls/issues}/comments"
  cd $LAB_TESTS_DIR
  bash $TESTS_DIR/run-tests.sh $TASK_NUMBER && echo "Success!" || echo "[CRITICAL] FAIL!" #TODO: Post comment with a failure
  cd $GITHUB_WORKSPACE
}

cd $GITHUB_WORKSPACE
cat pulls | while read pr_link; do
  processPullRequest $pr_link
done
