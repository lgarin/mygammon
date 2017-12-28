#!/bin/bash -e

curl -XPUT 'localhost:9200/_template/backgammon?pretty' -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["backgammon-*"],
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "doc": {
      "properties": {}
    }
  }
}
'
