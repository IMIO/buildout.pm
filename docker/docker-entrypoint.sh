#!/bin/bash
set -e

PRIORIY="instance-cron zeoserver"
CURL="curl --write-out '%{http_code}' -so /dev/null worker-cron:8087/standard/@@ok"

mkdir -p -m 777 /data/{log,filestorage,blobstorage}
python docker-initialize.py

if [[ $MOUNTPOINT ]]
then
  mkdir -p -m 777 "/data/blobstorage-$MOUNTPOINT"
fi

if [[ "instance" == "$1" || ! $PRIORIY == *"$1"* ]]
then
  echo "Waiting instance-cron ..."
  sleep 20
  response=$($CURL)
  echo "received response  $response"
  while [[ "$response" != "'200'" ]]
  do
    echo "Waiting instance-cron ..."
    sleep 10
    response=$($CURL)
    echo "received response  $response"
  done
fi

if [[ "instance-cron" == "$1" ]]
then
  echo "Setting ACTIVE_BIGBANG"
  export ACTIVE_BIGBANG="True"
fi

echo "Starting $1"
exec "bin/python" "bin/$1" "fg"

