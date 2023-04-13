#!/bin/bash

function check() {
  if [[ ! -f /data/filestorage/$1.fs ]]
  then
    echo "FAILURE : /data/filestorage/$1.fs not found"
    ls -l /data/filestorage/
    exit 1
  fi
  if [[ ! -d /data/$2 ]]
  then
    echo "FAILURE : /data/$2 not found"
    ls -l /data/
    exit 1
  fi
}

function pack() {
  if [[ $# -eq 0 ]]
  then
    db="1"
    blob="blobstorage"
    echo "Packing default database"
    check "Data" "$blob"
  else
    db="$1"
    blob="$2"
    echo "Packing $db database"
    check "$db" "$blob"
  fi
  CMD="/plone/bin/python /plone/bin/zeopack -D 0 -S $db -B /data/$blob"
  echo "Executing $CMD"
  eval "$CMD"
  echo
}

echo "----------Start of Databases packing $(date --rfc-2822)----------"
echo
pack
pack "async" "blobstorage"

if [ "$MOUNTPOINT" ]
then
  echo "Found mountpoint = $MOUNTPOINT"
  pack "$MOUNTPOINT" "blobstorage-$MOUNTPOINT"
else
  echo "Mountpoint not found"
fi
echo "----------End of Databases packing $(date --rfc-2822)----------"