#!/bin/bash
echo "----------Start of Databases packing $(date --rfc-2822)----------"
echo
CMD="/plone/bin/python /plone/bin/zeopack"
echo "Executing $CMD"
eval "$CMD"

if [ "$MOUNTPOINT" ]
then
  echo "Found mountpoint = $MOUNTPOINT"
  CMD="/plone/bin/python /plone/bin/zeopack -S $MOUNTPOINT -B /data/blobstorage-$MOUNTPOINT"
  echo "Executing $CMD"
  eval "$CMD"
else
  echo "Mountpoint not found"
fi
echo
echo "----------End of Databases packing $(date --rfc-2822)----------"
