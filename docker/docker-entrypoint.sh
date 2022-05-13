#!/bin/bash
set -e

function setup() {
  mkdir -pv /data/{log,filestorage,blobstorage}
  bin/python docker-initialize.py

  if [[ $MOUNTPOINT ]]; then
    mkdir -pv "/data/blobstorage-$MOUNTPOINT"
  fi

  if [[ "instance-cron" == "$1" ]]; then
    echo "Setting ACTIVE_BIGBANG"
    export ACTIVE_BIGBANG="True"
  fi
  chmod 777 /data/*
}
function wait_for_cron() {
  echo "Waiting for cron"
  URL="worker-cron:8087/$PLONE_PATH"
  CURL="curl --write-out %{http_code} -so /dev/null $URL/@@ok"
  MAX_TRIES=50
  INTERVAL=5
  set +e
  SECONDS=0
  response="$($CURL)"
  tries=1
  while [[ $response != "200" && $tries -lt $MAX_TRIES ]]
  do
    echo "Waiting for cron"
    sleep $INTERVAL
    response=$($CURL)
    ((tries+=1))
  done
  set -e
  if [[ $tries == "$MAX_TRIES" ]]; then
    echo "Failed to reach $URL after $SECONDS s"
    exit 1
  else
    echo "$URL is up. Waited $SECONDS s"
  fi
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
  shift
  echo "Executing maintenance command : '$*'"
  exec "$@"
  ;;
*)
  start "$1"
  ;;
esac
