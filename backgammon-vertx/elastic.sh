#!/bin/bash -e

curl -XPUT 'localhost:9200/_template/backgammon?pretty' -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["backgammon-*"],
  "settings": {
    "number_of_shards": 1,
    "max_result_window" : 100000
  },
  "mappings": {
    "doc": {
      "properties": {}
    }
  }
}
'
