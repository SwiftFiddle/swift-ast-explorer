#!/bin/bash -e
echo ""
echo "|************************|"
echo "|     NPM Publishing     |"
echo "|************************|"
echo ""
echo "This script will publish a new version to NPM, create a version bump git commit, tag it and push it."
read -p  "Press [Enter] to continue";

branchName=`git rev-parse --abbrev-ref HEAD`

if [[ $branchName != "master" ]]; then
  echo "Current branch is $branchName. Only the master branch can be published."
  exit 1
fi

containsChanges=`git status --short --untracked-files=no`

if [[ $containsChanges ]]; then
  echo "Branch contains uncommitted changes."
  echo "$containsChanges"
  exit 1
fi

containsDiffs=`git fetch && git diff master..origin/master --shortstat`

if [[ $containsDiffs ]]; then
  echo "Local/Origin branches are not in sync."
  echo $containsDiffs
  exit 1
fi

echo "What type of publish?"

select version_type in "patch" "minor" "major"; do
  read -p "Creating commit and tag for a $version_type release. Press [Enter] to continue";
  break
done

npm run lint
npm run compile
npm run test

open ./test/browser/index.html

read -p "Are browser tests OK? Press [Enter] to continue";

# Use npm to increment the version and capture it
version_with_v=`npm version $version_type -m "Version Bump to %s ($version_type)"`

# Remove the "v" from v1.2.3 to get 1.2.3 to tag without the "v"
version=`echo $version_with_v | cut -b 2-`

git tag -d $version_with_v &>/dev/null
git tag $version

packageName=`npm pkg get name | xargs echo`
registry=`npm config get registry`
gitOriginUrl=`git remote get-url origin`

read -p "Ready to publish $packageName@$version to $registry. Press [Enter] to continue"
npm publish --ignore-scripts

read -p "Ready to push master to $gitOriginUrl. Press [Enter]"
git push origin master
git push origin $version
