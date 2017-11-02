#!/bin/bash

. $(dirname $0)/globals
. $(dirname $0)/functions

LAST_UNLOCKED=0

(
while :
do
	UNLOCKED=1
	if ! geth_unlockaccount
	then
		UNLOCKED=0
 		echo ERROR: unlock failed 
	else
		if (( LAST_UNLOCKED == 0 ))
		then
 			echo INFO: unlocked
		fi
	fi
	LAST_UNLOCKED=$UNLOCKED
	sleep 15
done
) 2>&1 | sed -u 's/^/UNLOCK: /'

