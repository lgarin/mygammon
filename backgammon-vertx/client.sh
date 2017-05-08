#!/bin/bash -e

./ceylonb compile-js --offline --compact backgammon.shared backgammon.client
./ceylonb copy --offline --out=client --js --with-dependencies --include-language backgammon.client
