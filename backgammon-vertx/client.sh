#!/bin/bash -e

export JAVA_HOME=/C/Dev/jdk8

./ceylonb compile-js --offline --compact backgammon.shared backgammon.client
./ceylonb copy --offline --out=client --js --with-dependencies --include-language backgammon.client
