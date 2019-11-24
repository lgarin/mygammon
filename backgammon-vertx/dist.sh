#!/bin/bash -e

./ceylonb.bat compile --offline --out=dist/modules --overrides=overrides.xml backgammon.shared backgammon.server
./ceylonb.bat compile-js --offline --compact backgammon.shared backgammon.client
./ceylonb.bat copy --offline --out=dist/client --js --with-dependencies --include-language backgammon.client