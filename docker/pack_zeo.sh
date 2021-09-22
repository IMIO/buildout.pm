#!/bin/bash
echo "----------Start of Databases packing $(date --rfc-2822)----------"

CMD="/plone/bin/python /plone/bin/zeopack"
echo "Executing $CMD"
eval "$CMD"

if [[ -v "$($MOUNTPOINT)" ]]
then
  echo "Found mountpoint = $($MOUNTPOINT)"
  CMD="/plone/bin/python /plone/bin/zeopack -S $($MOUNTPOINT) -B /data/blobstorage-$($MOUNTPOINT)"
  echo "Executing $CMD"
  eval "$CMD"
fi

echo "----------End of Databases packing $(date --rfc-2822)----------"
