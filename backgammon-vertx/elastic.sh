#!/bin/bash -e

curl -XPUT 'localhost:9200/playerroster'
curl -XPUT 'localhost:9200/playerroster/_mapping/doc' -H 'Content-Type: application/json' -d '{"properties":{}}'