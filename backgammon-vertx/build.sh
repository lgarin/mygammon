#!/bin/bash -e
JAVA_HOME=/c/Dev/jdk8
DIST_DIR=//gd04b/dev/backgammon/dist
VERSION_PATTERN="[0-9]+\.[0-9]+\.[0-9]+"
VERSION=1.1.0

if [ -d $DIST_DIR ]; then
  rm -r $DIST_DIR
fi
mkdir $DIST_DIR

./ceylonb version --set $VERSION --confirm=none backgammon.shared backgammon.server backgammon.client backgammon.test
sed -i -r "s/(backgammon.client.)$VERSION_PATTERN/\1$VERSION/g" static/board.html
./ceylonb compile --offline --out=$DIST_DIR/modules backgammon.shared
./ceylonb compile --offline --out=$DIST_DIR/modules backgammon.server
./ceylonb copy --offline --out=$DIST_DIR/client --js --with-dependencies backgammon.client
cp -r static $DIST_DIR

git add .
git commit "Released version $VERSION"
git tag $VERSION
