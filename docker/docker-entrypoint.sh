#!/bin/bash
set -e

PRIORIY="instance-cron zeoserver"
CURL="curl --write-out '%{http_code}' -so /dev/null worker-cron:8087/standard/@@ok"

mkdir -p -m 777 /data/{log,instance-debug,filestorage,blobstorage,instance-async,instance-amqp,instance1}
python docker-initialize.py

if [[ ! $PRIORIY == *"$1"* ]]
then
  echo "Wating instance-cron ..."
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
echo "Starting $1"
exec "bin/python" "bin/$1" "fg"

