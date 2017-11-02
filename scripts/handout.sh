#!/bin/bash

. $(dirname $0)/functions

(
T=$(string2hex "handout")
PING=300 # 5 min
while :
do
	echo INFO: top of main loop

	# block if offline
	offline_barrier

	# start over if geth not running
	if ! geth_pid >/dev/null 2>&1
	then
		echo ERROR: geth not running
		sleep 15
		continue
	fi

	if test ! -r $COLONUS_DIR/accounts
	then
		echo "ERROR: cannot read $COLONUS_DIR/accounts"
		sleep 15
		continue
	fi

	MYA=$(head -1 $COLONUS_DIR/accounts)

	if (( $(echo -n $MYA | wc -c) != 40 ))
	then
		echo "ERROR: $MYA not valid account, != 40"
		sleep 15
		continue
	fi

	if (( $(echo -n $MYA | sed -r 's/[0-9a-fA-F]//g' | wc -c) != 0 ))
	then
		echo "ERROR: $MYA not valid account format"
		sleep 15
		continue
	fi

	# info for debug
	if ! BALANCE=$(geth_accountbalance $MYA)
	then
		continue
	fi
	echo INFO: current BALANCE=$BALANCE

	if ! PENDING=$(geth_pendingbalance $MYA)
	then
		continue
	fi
	echo INFO: current PENDING BALANCE=$PENDING

	# dont whisper unless I really need the coin
	PING_TIME=$(date +%s)
	LAST_BALANCE=$BALANCE
	echo INFO: start of balance/ping loop
	while :
	do
		if ! PENDING=$(geth_pendingbalance $MYA)
		then
			continue 2
		fi

 		if (( $(bc <<< "$PENDING < 10^18") == 1 ))
		then
			echo INFO: requesting handout, PENDING=$PENDING
			break
		fi

		if ! BALANCE=$(geth_accountbalance $MYA)
		then
			continue 2
		fi

 		if (( $(bc <<< "$BALANCE < 10^18") == 1 ))
		then
			echo INFO: waiting for funds, BALANCE=$BALANCE PENDING=$PENDING
		fi

		if [ "$LAST_BALANCE" != "$BALANCE" ]
		then
			echo INFO: change in balance, BALANCE=$BALANCE LAST_BALANCE=$LAST_BALANCE
			LAST_BALANCE=$BALANCE
		fi

		if (( ($(date +%s) - PING_TIME) > $PING ))
		then
 			if (( $(bc <<< "$BALANCE < 10^18") == 1 ))
			then
				echo ERROR: TIMEOUT ON PENDING, RESEND REQUEST, BALANCE=$BALANCE PENDING=$PENDING
				break
			fi
		fi
		sleep 15
	done

	BLOCK_COUNT=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
	PEER_COUNT=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq -r '.result')
	SYNCING=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq -r '.result')
	if [ "$SYNCING" != "false" ]
	then
		SYNCING=true
	fi

	UPTIME=$(cat /proc/uptime | awk '{print $1}')

	M="$MYA,$RANDOM,$(date -u --rfc-3339=ns),$HOSTNAME,$BLOCK_COUNT,$PEER_COUNT,$SYNCING,$UPTIME"
	echo INFO: input string: $M
	M=$(string2hex "$M")
	echo INFO: message string: $M

	while :
	do
		echo INFO: top of message loop

		# use existing shhid if possible, else get new and save
		if test -s $COLONUS_DIR/shhid
		then
			echo INFO: using existing shhid
			ID=$(cat $COLONUS_DIR/shhid)
		else
			while ! ID=$(geth_getwhisperid)
			do
				echo ERROR: geth_getwhisperid failed
				sleep 10
			done
			echo INFO: got new shhid
			echo $ID >$COLONUS_DIR/shhid
		fi

		# check shhid
		R=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"shh_hasIdentity","params":["'$ID'"],"id":1}' | jq -r '.result')

		# no result?  geth may have died
		if test -z "$R"
		then
			echo ERROR: ID check no results, start from the top
			break
		fi

		# if shhid no good remove cached shhid and try again
		if [ "$R" != "true" ]
		then
			echo ERROR: ID no good, getting new ID
			rm -f $COLONUS_DIR/shhid
			continue
		fi

		# finally whisper something
		R=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"shh_post","params":[{"from":"'$ID'","topics": ["0x'$T'"],"payload":"0x'$M'","ttl":"0xf","priority":"0x64"}],"id":1}' | jq -r '.result')

		if [ "$R" = "true" ]
		then
			# well, well, no prob
			echo INFO: message sent!
			break	
		fi

		echo ERROR: whisper failed, try again
	done

	sleep 15
done 
) 2>&1 | sed -u 's/^/HANDOUT: /'

