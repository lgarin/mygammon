#!/bin/bash -e

DIST_DIR=//rvz03/dev/backgammon/dist
VERSION_PATTERN="[0-9]+\.[0-9]+\.[0-9]+"

CURRENT_VERSION=$(sed -rn "s/.*backgammon.client.($VERSION_PATTERN).*/\1/gp" static/board.html)
read V_MAJOR V_MINOR V_PATCH <<<$(IFS="."; echo $CURRENT_VERSION)
if [[ -z "$V_MAJOR" || -z "$V_MINOR" || -z "$V_PATCH" ]] ; then
  echo "Unable to detect current version"
  exit 1
fi 
NEW_VERSION="$V_MAJOR.$V_MINOR.$((V_PATCH + 1))"

echo "Building version $CURRENT_VERSION"
mkdir -p $DIST_DIR/modules || rm -r $DIST_DIR/modules/*
./ceylonb compile --offline --out=$DIST_DIR/modules --overrides=resource/overrides.xml backgammon.shared backgammon.server
mkdir -p $DIST_DIR/client || rm -r $DIST_DIR/client/*
./ceylonb compile-js --offline --overrides=resource/overrides.xml --compact backgammon.shared backgammon.client
./ceylonb copy --offline --overrides=resource/overrides.xml --out=$DIST_DIR/client --js --with-dependencies --include-language backgammon.client
mkdir -p $DIST_DIR/static || rm -r $DIST_DIR/static/*
cp -r static/* $DIST_DIR/static
git tag -f -a -m "Released version $CURRENT_VERSION" $CURRENT_VERSION

echo "Preparing next version $NEW_VERSION"
./ceylonb version --set $NEW_VERSION --confirm=none backgammon.shared backgammon.server backgammon.client backgammon.test
sed -i -r "s/(backgammon.client.)$VERSION_PATTERN/\1$NEW_VERSION/g" static/*.html
unix2dos static/*.html
sed -i -r "s/(backgammon.server.)$VERSION_PATTERN/\1$NEW_VERSION/g" *.launch
unix2dos *.launch
git add .
git commit -m "Version bump to $NEW_VERSION"