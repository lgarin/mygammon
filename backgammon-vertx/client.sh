#!/bin/bash -e
export JAVA_HOME=/c/Dev/jdk8

./ceylonb compile-js --offline --compact backgammon.shared backgammon.client
#for ceylon 1.3.1 add --include-language
./ceylonb copy --offline --out=client --js --with-dependencies backgammon.client
