#!/bin/bash

for i in "$@"; do
  case $i in
  -s=* | --server=*)
    echo "source found ${i#*=}"
    SOURCE_HOST="${i#*=}"
    shift # past argument=value
    ;;
  -b=* | --buildout=*)
    echo "buildout found ${i#*=}"
    SOURCE_PATH="/srv/instances/${i#*=}"
    shift # past argument=value
    ;;
  *)    # unknown option
    ;;
  esac
done

echo "SOURCE_HOST : ${SOURCE_HOST}"
echo "SOURCE_PATH : ${SOURCE_PATH}"
echo
date

echo
echo "Copying ${SOURCE_HOST}:${SOURCE_PATH} filestorage:"
CMD="rsync -ah --info=progress2 zope@${SOURCE_HOST}:${SOURCE_PATH}/var/filestorage/*.fs var/filestorage/ --delete"
eval "${CMD}"
echo
echo "Copying ${SOURCE_HOST}:${SOURCE_PATH} blobstorage:"
CMD="rsync -ah --info=progress2 --exclude '*.old' zope@${SOURCE_HOST}:${SOURCE_PATH}/var/blobstorage* var/ --delete"
eval "${CMD}"
echo
date
