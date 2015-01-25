#!/bin/bash

#
# Place this script somewhere like .travis/github-release.sh
# then add something like this to your .travis.yml:
#
# after_success: .travis/github-release.sh "$TRAVIS_REPO_SLUG" "`head -1 src/VERSION`" build/release/*
#
# The first argument is your repository in the format
# "username/repository", which Travis provides in the
# TRAVIS_REPO_SLUG environment variable.
#
# The second argument is the release version which as a
# sanity check should match the tag that you are releasing.
# You could pass "`git describe`" to satisfy this check.
#
# The remaining arguments are a list of asset files that you
# want to publish along with the release.
#
# The script requires that you create a GitHub OAuth access
# token to facilitate the upload:
#
# https://help.github.com/articles/creating-an-access-token-for-command-line-use
#
# You must pass this securely in the GITHUBTOKEN environment
# variable:
#
# http://docs.travis-ci.com/user/build-configuration/#Secure-environment-variables
#
# For testing purposes you can create a local convenience
# file in the script directory called GITHUBTOKEN that sets
# the GITHUBTOKEN environment variable. If you do so you MUST
# ensure that this doesn't get pushed to your repository,
# perhaps by adding it to a .gitignore file.
#
# Should you get stuck then look at a working example. This
# code is being used by Barcode Writer in Pure PostScript
# for automated deployment:
#
# https://github.com/terryburton/postscriptbarcode

set -e

REPO=$1 && shift
RELEASE=$1 && shift
RELEASEFILES=$@

if ! TAG=`git describe --exact-match 2>/dev/null`; then
  echo "This commit is not a tag so not creating a release"
  exit 0
fi

if [ "$TRAVIS" = "true" ] && [ -z "$TRAVIS_TAG" ]; then
  echo "This build is not for the tag so not creating a release"
  exit 0
fi

if [ "$TRAVIS" = "true" ] && [ "$TRAVIS_TAG" != "$RELEASE" ]; then
  echo "Error: TRAVIS_TAG ($TRAVIS_TAG) does not match the indicated release ($RELEASE)"
  exit 1
fi

if [ "$TAG" != "$RELEASE" ]; then
  echo "Error: The tag ($TAG) does not match the indicated release ($RELEASE)"
  exit 1
fi

if [[ -z "$RELEASEFILES" ]]; then
  echo "Error: No release files provided"
  exit 1
fi

SCRIPTDIR=`dirname $0`
[ -e "$SCRIPTDIR/GITHUBTOKEN" ] && . "$SCRIPTDIR/GITHUBTOKEN"
if [[ -z "$GITHUBTOKEN" ]]; then
  echo "Error: GITHUBTOKEN is not set"
  exit 1
fi

echo "Creating GitHub release for $RELEASE"

echo -n "Create draft release... "
JSON=$(cat <<EOF
{
  "tag_name":         "$TAG",
  "target_commitish": "master",
  "name":             "$TAG: New release",
  "draft":            true,
  "prerelease":       false
}
EOF
)
RESULT=`curl -s -w "\n%{http_code}\n"     \
  -H "Authorization: token $GITHUBTOKEN"  \
  -d "$JSON"                              \
  "https://api.github.com/repos/$REPO/releases"`
if [ "`echo "$RESULT" | tail -1`" != "201" ]; then
  echo FAILED
  echo "$RESULT"
  exit 1
fi
RELEASEID=`echo "$RESULT" | sed -ne 's/^  "id": \(.*\),$/\1/p'`
if [[ -z "$RELEASEID" ]]; then
  echo FAILED
  echo "$RESULT"
  exit 1
fi
echo DONE

for FILE in $RELEASEFILES; do
  if [ ! -f $FILE ]; then
    echo "Warning: $FILE not a file"
    continue
  fi
  FILESIZE=`stat -c '%s' "$FILE"`
  FILENAME=`basename $FILE`
  echo -n "Uploading $FILENAME... "
  RESULT=`curl -s -w "\n%{http_code}\n"                   \
    -H "Authorization: token $GITHUBTOKEN"                \
    -H "Accept: application/vnd.github.manifold-preview"  \
    -H "Content-Type: application/zip"                    \
    --data-binary "@$FILE"                                \
    "https://uploads.github.com/repos/$REPO/releases/$RELEASEID/assets?name=$FILENAME&size=$FILESIZE"`
  if [ "`echo "$RESULT" | tail -1`" != "201" ]; then
    echo FAILED
    echo "$RESULT"
    exit 1
  fi
  echo DONE
done

echo -n "Publishing release... "
JSON=$(cat <<EOF
{
  "draft": false
}
EOF
)
RESULT=`curl -s -w "\n%{http_code}\n"     \
  -X PATCH                                \
  -H "Authorization: token $GITHUBTOKEN"  \
  -d "$JSON"                              \
  "https://api.github.com/repos/$REPO/releases/$RELEASEID"`
if [ "`echo "$RESULT" | tail -1`" = "200" ]; then
  echo DONE
else
  echo FAILED
  echo "$RESULT"
  exit 1
fi