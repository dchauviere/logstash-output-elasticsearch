#!/bin/bash
set -x

setup_es() {
  download_url=$1
  curl -sL $download_url > elasticsearch.tar.gz
  mkdir elasticsearch
  tar -xzf elasticsearch.tar.gz --strip-components=1 -C ./elasticsearch/.
  ln -sn ../../spec/fixtures/scripts elasticsearch/config/.
}

start_es() {
  elasticsearch/bin/elasticsearch $@ > /tmp/elasticsearch.log &
  sleep 10
  curl http://localhost:9200 && echo "ES is up!" || cat /tmp/elasticsearch.log
}

if [[ "$INTEGRATION" != "true" ]]; then
  bundle exec rspec -fd spec
else
  if [[ "$ES_VERSION" == 5.* ]]; then
    setup_es https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$ES_VERSION/elasticsearch-$ES_VERSION.tar.gz
    start_es -Ees.script.inline=true -Ees.script.indexed=true -Ees.script.file=true
    bundle exec rspec -fd spec --tag integration --tag version_5x
  else
    setup_es https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ES_VERSION.tar.gz
    start_es -Des.script.inline=on -Des.script.indexed=on -Des.script.file=on
    bundle exec rspec -fd spec --tag integration --tag ~version_5x
  fi
  if [[ $? -ne 0 ]]; then
    cat /tmp/elasticsearch.log
    exit 1
  fi
fi
