#!/bin/bash
set -e

function setup() {
  mkdir -pv /data/{log,filestorage,blobstorage}
  bin/python docker-initialize.py

  if [[ $MOUNTPOINT ]]; then
    mkdir -pv "/data/blobstorage-$MOUNTPOINT"
  fi
  chmod 777 /data/*
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
	# ensure file exists otherwise logtail returns 1
	touch "/data/log/$HOSTNAME.log"
	exec "$cmd" "logtail"
}

setup "$1"

case "$1" in
"")
  exit 0
  ;;
"maintenance")
  shift
  echo "Executing maintenance command : '$*'"
  set -x
  exec "$@"
  ;;
"script")
  shift
  script=$1
  shift
  command="bin/instance-debug -O $PLONE_PATH run scripts/$script.py $*"
  echo "Executing script : $command'"
  set -x
  eval "$command"
  ;;
*)
  start "$1"
  ;;
esac
