#!/bin/bash

rm -rf blockchain.* .ethereum

SITE=169.44.63.234 #dal
#SITE=159.122.228.25 #lon
#SITE=161.202.82.19 #tok

FILE=$(curl -s http://$SITE/blockchain.url)
sync; echo 3 > /proc/sys/vm/drop_caches

TIME=$(date +%s)

curl --speed-limit 1 --speed-time 30 -sL $SITE/$FILE | gunzip | tar xvf -

echo Download/Extract TIME: $(( $(date +%s) - TIME ))

