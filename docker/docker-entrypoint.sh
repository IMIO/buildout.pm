#!/bin/bash
set -e

mkdir -p -m 777 /data/{log,instance-debug,filestorage,blobstorage,instance-async,instance-amqp,instance1}
python docker-initialize.py

exec "bin/python" "bin/$1" "fg"

