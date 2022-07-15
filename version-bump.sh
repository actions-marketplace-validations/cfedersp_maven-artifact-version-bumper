#!/bin/bash

# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#
# Takes a version number, and the mode to bump it, and increments/resets
# the proper components so that the result is placed in the variable
# `NEW_VERSION`.
#
# $1 = mode (major, minor, patch)
# $2 = version (x.y.z)
#
function bump {
  local mode="$1"
  local old="$2"
  local parts=( ${old//./ } )
  local lastElement=${parts[${#parts[@]}-1]}
  local patchAndPreReleaseLabel=(${lastElement//-/ })
  case "$1" in
    major)
      local bv=$((parts[0] + 1))
      NEW_VERSION="${bv}.0.0"
      ;;
    minor)
      local bv=$((parts[1] + 1))
      NEW_VERSION="${parts[0]}.${bv}.0"
      ;;
    patch)
      local bv=$((patchAndPreReleaseLabel[0] + 1))
      NEW_VERSION="${parts[0]}.${parts[1]}.${bv}"
      ;;
    esac
  if [ ! -z ${patchAndPreReleaseLabel[1]} ]; then
    NEW_VERSION="${NEW_VERSION}-${patchAndPreReleaseLabel[1]}"
  fi
}

git config --global user.email $EMAIL
git config --global user.name $NAME

OLD_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

BUMP_MODE="none"
if git log -1 | grep -q "#major"; then
  BUMP_MODE="major"
elif git log -1 | grep -q "#minor"; then
  BUMP_MODE="minor"
else
  BUMP_MODE="patch"
fi

REPO="https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git"

if [[ "${READ_ONLY}" == "true" ]]
then
  echo "Read-only mode: pom.xml at" $POMPATH "will remain at" $OLD_VERSION
elif [[ "${ARTIFACT_TYPE}" == "service" ]]
then
  git tag --force $OLD_VERSION
  git push $REPO --follow-tags --force
  git push $REPO --tags --force
  
  echo $BUMP_MODE "version bump detected"
  bump $BUMP_MODE $OLD_VERSION
  echo "pom.xml at" $POMPATH "will be bumped from" $OLD_VERSION "to" $NEW_VERSION
  mvn -q versions:set -DnewVersion="${NEW_VERSION}"
  git add $POMPATH/pom.xml
  git commit -m "Bump pom.xml from $OLD_VERSION to $NEW_VERSION"
  git push
elif [[ "${ARTIFACT_TYPE}" == "dependency" ]]
then
  git tag --force  $OLD_VERSION
  git push $REPO --follow-tags --force
  git push $REPO --tags --force
fi
