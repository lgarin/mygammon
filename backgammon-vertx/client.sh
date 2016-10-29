#!/bin/bash -e
export JAVA_HOME=/c/Dev/jdk8

./ceylonb compile-js --offline --compact backgammon.shared backgammon.client
./ceylonb copy --offline --out=client --js --with-dependencies backgammon.client
