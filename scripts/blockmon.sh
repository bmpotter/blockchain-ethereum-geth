#!/bin/bash

. $(dirname $0)/functions

(
STATUS_TIME=600
STATUS_LT=$(date +"%s")
BLOCK_TIMEOUT=300
PEER_TIMEOUT=120
LAST_BLOCK_COUNT=0
STATUS=100
LT=$(date +"%s")
while :
do
	# block if offline
	offline_barrier

	# start over if geth not running
	if ! geth_pid >/dev/null 2>&1
	then
		test $STATUS = 1 || echo ERROR: geth not running
		STATUS=1
		sleep 15
		LT=$(date +"%s")
		continue
	fi

 	if (( ($(date +%s) - STATUS_LT) > $STATUS_TIME ))
	then
		echo "STATUS: BLOCK_COUNT: $(($BLOCK_COUNT)) PEER_COUNT: $(($PEER_COUNT)) SYNCING: $SYNCING"
		STATUS_LT=$(date +"%s")
		if ((PEER_COUNT > 0 ))
		then
			curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' | jq -r '.result[]|.name,.network.remoteAddress' | paste -d " " - - | sed -u 's/^/PEERS: /'
		fi
	fi

	sleep 20

	# peer check with peer reset counter as well
	PEER_COUNT=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq -r '.result')
	if test -z "$PEER_COUNT"
	then
		test $STATUS = 2 || echo ERROR: geth rpc down
		STATUS=2
		LT=$(date +"%s")
		continue
	fi
	if ((PEER_COUNT == 0))
	then
		test $STATUS = 3 || echo "ERROR: no peers"
		STATUS=3
		T=$(date +"%s")
		if (( (T - LT) > $PEER_TIMEOUT ))
		then
			STATUS=13
			echo "ERROR: PEER STALL! TIME: $((T - LT)) BLOCK_COUNT: $(($BLOCK_COUNT))"
			echo "ACTION: killing geth"
			geth_kill
			LAST_BLOCK_COUNT=0
			LT=$(date +"%s")
		fi
		continue
	fi

	# ok, geth running, got peers, but is it still syncing (normal state right after start or under great load)
	SYNCING=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq -r '.result')
	if [ "$SYNCING" != "false" ]
	then
		test $STATUS = 4 || echo "INFO: syncing"
		STATUS=4
		LT=$(date +"%s")
		continue
	fi

	# if geth running, got peers, no syncing, and after 20 seconds check if block changed, if changed, then continue
    BLOCK_COUNT=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
	if test -z "$BLOCK_COUNT"
	then
		test $STATUS = 5 || echo ERROR: geth rpc down
		STATUS=5
		LT=$(date +"%s")
		continue
	fi
	if ((LAST_BLOCK_COUNT < BLOCK_COUNT))
	then
		test $STATUS = 0 || echo "INFO: RECOVERED: BLOCK_COUNT: $(($BLOCK_COUNT)) PEER_COUNT: $(($PEER_COUNT)) SYNCING: $SYNCING"
		STATUS=0
		LAST_BLOCK_COUNT=$BLOCK_COUNT
		LT=$(date +"%s")
		continue
	fi

	# ok, geth running, got peers, not syncing, and block has not changed in 20 sec,
	# check for time since last block change and reset geth if XXX sec
	T=$(date +"%s")
 	if (( (T - LT) > $BLOCK_TIMEOUT ))
	then
		STATUS=20
		echo "ERROR: BLOCK STALL! TIME: $((T - LT)) BLOCK_COUNT: $(($BLOCK_COUNT))"
		echo "ACTION: killing geth"
		geth_kill
		LAST_BLOCK_COUNT=0
		LT=$(date +"%s")
	fi
done 
) 2>&1 | sed -u 's/^/BLOCKMON: /'
