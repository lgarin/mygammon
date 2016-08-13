#!/bin/bash -e
JAVA_HOME=/c/Dev/jdk8
DIST_DIR=//gd04b/dev/backgammon/dist
VERSION_PATTERN="[0-9]+\.[0-9]+\.[0-9]+"

CURRENT_VERSION=$(sed -rn "s/.*backgammon.client.($VERSION_PATTERN).*/\1/gp" static/board.html)
read V_MAJOR V_MINOR V_PATCH <<<$(IFS="."; echo $CURRENT_VERSION)
V_PATCH=$((V_PATCH + 1))
NEW_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"

echo "Building version $CURRENT_VERSION"
if [ -d $DIST_DIR ]; then
  rm -r $DIST_DIR
fi
mkdir $DIST_DIR
./ceylonb compile --offline --out=$DIST_DIR/modules backgammon.shared
./ceylonb compile --offline --out=$DIST_DIR/modules backgammon.server
./ceylonb copy --offline --out=$DIST_DIR/client --js --with-dependencies backgammon.client
cp -r static $DIST_DIR
git tag -f -a -m "Released version $CURRENT_VERSION" $CURRENT_VERSION

echo "Preparing next version $NEW_VERSION"
./ceylonb version --set $NEW_VERSION --confirm=none backgammon.shared backgammon.server backgammon.client backgammon.test
sed -i -r "s/(backgammon.client.)$VERSION_PATTERN/\1$NEW_VERSION/g" static/board.html
git add .
git commit -m "Version bump to $VERSION"
