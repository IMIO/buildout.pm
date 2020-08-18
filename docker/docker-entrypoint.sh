#!/bin/bash
set -e

COMMANDS="debug help logtail show stop adduser fg kill quit run wait console foreground logreopen reload shell status"
START="start restart zeoserver"
CMD="bin/instance1"
ARGS="$@"

python /docker-initialize.py
mkdir -p /home/plone/plone-pm/var/{log,instance-debug,filestorage,blobstorage,instance-async,instance-amqp,instance1}

if [ -e "custom.cfg" ]; then
	if [ ! -e "bin/develop" ]; then
		buildout -c custom.cfg
		python /docker-initialize.py
	fi
fi

if [[ "$1" == "zeoserver"* ]]; then
	CMD="bin/$1"
fi

if [[ "$1" == "instance-async"* ]]; then
	CMD="bin/instance-async"
	ARGS="$CMD $2"
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
		exec $CMD "$ARGS"
	fi
	exec $ARGS
fi
