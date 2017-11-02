#!/bin/bash


geth_accountbalance()
{
	ACCOUNT=0x${1}

	if R=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:8545 -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["'$ACCOUNT'","latest"],"id":1}' | jq -r '.result' ; exit $(( $PIPESTATUS + $? )) )
	then
		BAL=$(echo $R | tr 'a-f' 'A-F'| awk -Fx '{print $2}')
		echo "ibase=16; $BAL" | bc
		return 0
	fi

	echo 0
	return 1
}

geth_pendingbalance()
{
	ACCOUNT=0x${1}

	if R=$(curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:8545 -X POST --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["'$ACCOUNT'","pending"],"id":1}' | jq -r '.result' ; exit $(( $PIPESTATUS + $? )) )
	then
		BAL=$(echo $R | tr 'a-f' 'A-F'| awk -Fx '{print $2}')
		echo "ibase=16; $BAL" | bc
		return 0
	fi

	echo 0
	return 1
}

test1()
{
	echo killing old instance
	export INSTANCE_NAME=client
	docker rm -f $INSTANCE_NAME

	echo cleaning up old data
	export LOCAL_DATA_DIR=/ssd/geth_root_user
	rm -rf $LOCAL_DATA_DIR
	mkdir -p $LOCAL_DATA_DIR

	export LOCAL_PORT=8545
	export RAM=128m # for 1GB system

	echo 3 > /proc/sys/vm/drop_caches

	docker run -m $RAM -d -t --name $INSTANCE_NAME -v $LOCAL_DATA_DIR:/root -p 127.0.0.1:$LOCAL_PORT:8545 $(uname -m)/geth start.sh

	ACCOUNT_FILE=$LOCAL_DATA_DIR/.colonus/accounts

	echo waiting for account file
	while [ ! -s "$ACCOUNT_FILE" ]
	do
		sleep 1
	done

	cat $ACCOUNT_FILE

	echo waiting for balance
	TIMEOUT=1000
	START=$(date +%s)
	B=0
	while [ "$B" = "0" ]
	do
		if (( $(date +%s) - START > TIMEOUT ))
		then
			echo "TIMEOUT: check logs" >&2
			return 1
		fi
		B=$(geth_accountbalance $(cat $ACCOUNT_FILE))
		sleep 5
	done

	echo 3 > /proc/sys/vm/drop_caches

	echo TIME: $(( $(date +%s) - START )) >&2
	return 0
}

COUNT=0
while test1
do
	COUNT=$((COUNT + 1))
	echo "COUNT: $COUNT"
done
