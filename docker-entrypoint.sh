#!/bin/bash
set -e

COMMANDS="debug help logtail show stop adduser fg kill quit run wait console foreground logreopen reload shell status"
START="start restart zeoserver"
CMD="bin/instance1"

python /docker-initialize.py
mkdir -p /home/imio/imio-pm/var/{log,instance-debug,filestorage,blobstorage,instance-async,instance-amqp,instance1}

if [ -e "custom.cfg" ]; then
	if [ ! -e "bin/develop" ]; then
		buildout -c custom.cfg
		python /docker-initialize.py
	fi
fi

if [[ "$1" == "zeo"* ]]; then
	CMD="bin/$1"
fi

if [ -z "$HEALTH_CHECK_TIMEOUT" ]; then
	HEALTH_CHECK_TIMEOUT=1
fi

if [ -z "$HEALTH_CHECK_INTERVAL" ]; then
	HEALTH_CHECK_INTERVAL=1
fi

if [[ $START == *"$1"* ]]; then
	_stop() {
		$CMD stop
		kill -TERM "$child" 2>/dev/null
	}

	trap _stop SIGTERM SIGINT
	$CMD start
  sleep 3
	$CMD logtail &
	child=$!

	pid=$($CMD status | sed 's/[^0-9]*//g')
	if [ -n "$pid" ]; then
		echo "Application running on pid=$pid"
		sleep "$HEALTH_CHECK_TIMEOUT"
		while kill -0 "$pid" 2>/dev/null; do
			sleep "$HEALTH_CHECK_INTERVAL"
		done
	else
		echo "Application didn't start normally. Shutting down!"
		_stop
	fi
else
	if [[ $COMMANDS == *"$1"* ]]; then
		exec bin/instance1 "$@"
	fi
	exec "$@"
fi
