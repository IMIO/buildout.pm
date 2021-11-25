#!/bin/bash
set -e

function setup() {
  mkdir -pvm 777 /data/{log,filestorage,blobstorage}
  python docker-initialize.py

  if [[ $MOUNTPOINT ]]; then
    mkdir -pvm 777 "/data/blobstorage-$MOUNTPOINT"
  fi

  if [[ "instance-cron" == "$1" ]]; then
    echo "Setting ACTIVE_BIGBANG"
    export ACTIVE_BIGBANG="True"
  fi
}
function wait_for_cron() {
  CURL="curl --write-out '%{http_code}' -so /dev/null worker-cron:8087/standard/@@ok"
  echo "Waiting instance-cron ..."
  sleep 20
  response=$($CURL)
  echo "received response  $response"
  while [[ "$response" != "'200'" ]]; do
    echo "Waiting instance-cron ..."
    sleep 10
    response=$($CURL)
    echo "received response  $response"
  done
}
function start() {
  echo "Starting $1"
  cmd="bin/$1"
  _stop() {
    echo "Forcing to stop"
    $cmd stop
    case "$cmd" in
    "bin/zeoserver")
      if [[ -f /data/filestorage/Data.fs.lock ]]; then
        kill -TERM "$(cat /data/filestorage/Data.fs.lock)" 2>/dev/null
      fi
      ;;
    *)
      ;;
    esac
	}

	trap _stop SIGTERM SIGINT
	$cmd start
	# ensure file xists otherwise logtail returns 1
	touch "/data/log/$HOSTNAME.log"
	exec "$cmd" "logtail"
}

setup "$1"

PRIORIY="instance-cron instance-debug maintenance zeoserver"
if [[ "instance" == "$1" || ! $PRIORIY == *"$1"* ]]; then
  wait_for_cron "$1"
fi

case "$1" in
"maintenance")
  exec "bash"
  ;;
*)
  start "$1"
  ;;
esac
