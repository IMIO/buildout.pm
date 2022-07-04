#! /bin/bash
curl -fS --http0.9 zeo:9100
if [[ $? == 0 || $? == 56 ]]; then
  exit 0
else
  exit 1
fi
