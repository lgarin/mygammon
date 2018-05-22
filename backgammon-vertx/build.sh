#!/bin/bash -e

DIST_DIR=//gd04b/dev/backgammon
VERSION_PATTERN="[0-9]+\.[0-9]+\.[0-9]+"

CURRENT_VERSION=$(sed -rn "s/.*backgammon.client.($VERSION_PATTERN).*/\1/gp" static/board.html)
read V_MAJOR V_MINOR V_PATCH <<<$(IFS="."; echo $CURRENT_VERSION)
if [[ -z "$V_MAJOR" || -z "$V_MINOR" || -z "$V_PATCH" ]] ; then
  echo "Unable to detect current version"
  exit 1
fi 
VERSION_DIR="$DIST_DIR/dist-$V_MAJOR.$V_MINOR.$V_PATCH"
NEW_VERSION="$V_MAJOR.$V_MINOR.$((V_PATCH + 1))"
NEW_VERSION="2.1.0"

echo "Building version $CURRENT_VERSION"
mkdir $VERSION_DIR
./ceylonb compile --offline --out=$VERSION_DIR/modules --overrides=overrides.xml backgammon.shared backgammon.server
./ceylonb compile-js --offline --compact backgammon.shared backgammon.client
./ceylonb copy --offline --out=$VERSION_DIR/client --js --with-dependencies --include-language backgammon.client
cp -r static $VERSION_DIR
git tag -f -a -m "Released version $CURRENT_VERSION" $CURRENT_VERSION

echo "Preparing next version $NEW_VERSION"
./ceylonb version --set $NEW_VERSION --confirm=none backgammon.shared backgammon.server backgammon.client backgammon.test
sed -i -r "s/(backgammon.client.)$VERSION_PATTERN/\1$NEW_VERSION/g" static/*.html
unix2dos static/*.html
sed -i -r "s/(backgammon.server.)$VERSION_PATTERN/\1$NEW_VERSION/g" *.launch
unix2dos *.launch
git add .
git commit -m "Version bump to $NEW_VERSION"