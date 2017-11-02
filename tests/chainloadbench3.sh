#!/bin/bash

rm -rf blockchain.* .ethereum

SITE=169.44.63.234 #dal
#SITE=159.122.228.25 #lon
#SITE=161.202.82.19 #tok

RETRIES=2
FILE=$(curl -s --retry $RETRIES http://$SITE/blockchain.url)
SIZE=$(curl -sI --retry $RETRIES http://$SITE/$FILE | awk '/Content-Length/ {print $2}' | tr -d '\r')
SLICES=25
SLICE=$(( SIZE / SLICES ))
EXTRASLICE=$(( SIZE % SLICES > 0 ))
sync; echo 3 > /proc/sys/vm/drop_caches 

TIME=$(date +%s)

for (( i=0; i < (SLICES + EXTRASLICE); i++ ))
do 
	curl -s --retry $RETRIES --range $((i * SLICE))-$(( ((i + 1) * SLICE) - 1 > (SIZE - 1) ? (SIZE - 1) : ((i + 1) * SLICE) - 1 )) -o blockchain.$(printf "%03d" $i) $SITE/$FILE &
	#sleep 0.5
done

echo Launch TIME: $(( $(date +%s) - TIME ))

for (( i=0; i < (SLICES + EXTRASLICE); i++ ))
do 
	SUBSIZE=$(( ( ((i + 1) * SLICE) - 1 > (SIZE - 1) ? (SIZE - 1) : ((i + 1) * SLICE) - 1 ) - (i * SLICE) + 1 ))
	SUBFILE=blockchain.$(printf "%03d" $i)

	while ! test -r $SUBFILE
	do
		sleep 0.1
	done

	while (( $(stat --printf="%s" $SUBFILE) != SUBSIZE ))
	do
		sleep 0.1
	done

	echo $SUBFILE downloaded >&2
	cat $SUBFILE
	rm -f $SUBFILE &
done | gunzip | tar xvf -

echo Download/Extract TIME: $(( $(date +%s) - TIME ))

