#!/bin/bash -e

./ceylonb compile-js --offline --compact backgammon.shared backgammon.client
#for ceylon 1.3.1 add --include-language
./ceylonb copy --offline --out=client --js --with-dependencies backgammon.client
