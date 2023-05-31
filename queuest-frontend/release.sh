#!/bin/bash

# if [ -z $1 ]; then
#         echo "Releasing queuest-frontend into gh-pages branch"
#         echo "Missed version"
#         echo "Usage: release.sh <release version>"
#         exit 1;
# fi

now=$(date +"%Y-%m-%d-%H.%M.%S")

echo "Releasing queuest-frontend $now"

git add --all
git commit -am "gh-pages pre-release $version"
rm -rf dist

if [ -z $1 ];
then
  version=$(npm version patch)
elif [ "$1" == "minor" ];
then
  version=$(npm version minor)
else
  version=$(npm version $1)
fi

npm run build
git add -A
git commit -am "prerelease $version"
git checkout gh-pages
git pull
rm *.js
rm *.json
rm *.txt
rm *.png
rm *.css
rm *.svg
rm *.html
cp -a dist/queuest-frontend/. .
rm -rf queuest-frontend/
rm -rf queuest-backend/
rm -rf out/
cp index.html 404.html
git add -A
git commit -am "gh-pages release $version"
git push
git checkout main