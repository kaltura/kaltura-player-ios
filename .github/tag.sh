#!/bin/bash

set -u

PODSPEC=*.podspec
POD=$(basename $PODSPEC .podspec)

pod ipc spec $POD.podspec > spec.json

TARGET_TAG=$(jq '.source.tag' --raw-output spec.json)
VERSION=$(jq '.version' --raw-output spec.json)

RELEASE_URL="https://github.com/$GITHUB_REPOSITORY/releases/tag/$TARGET_TAG"

# Release to GitHub (creates tag + release notes)
cat << EOF > post.json
{
  "name": "v$VERSION",
  "body": "# $POD \n\n [TBD] \n\n ## Cocoapods install \n\`pod '$POD', '~> $VERSION'\`",
  "tag_name": "$TARGET_TAG",
  "target_commitish": "$GITHUB_SHA"
}
EOF

POST_URL=https://api.github.com/repos/$GITHUB_REPOSITORY/releases

curl $POST_URL -X POST -H "Content-Type: application/json" -H "authorization: Bearer $GITHUB_TOKEN" -d@post.json
