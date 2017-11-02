#!/bin/bash

set -x

# setup vars
NETWORKID=$(cat /root/networkid)
ETHERBASE=$(cat /root/account0)
PORT=30303

NAT=""
test "$EXTIP" && NAT="--nat extip:$EXTIP" 

# init and join network
cd /root
mkdir -p .ethereum # to avoid geth y/N question

# speed up
mkdir -p .ethash
cd .ethash
if [ ! -r full-R23-0000000000000000 ]
then
	if [ -r /root/full-R23-0000000000000000 ]
	then
		cp /root/full-R23-0000000000000000 .
	else
		curl -sLO https://dal05.objectstorage.softlayer.net/v1/AUTH_b704aa6c-f8d8-44a5-91ea-d915acfb0b87/mtn/full-R23-0000000000000000
	fi
fi
cd ..

geth init /root/genesis.json

geth \
	--lightkdf \
	--shh \
	--jitvm=false \
	--rpcapi "admin,db,eth,debug,miner,net,shh,txpool,personal,web3" \
	--identity $HOSTNAME \
	--networkid $NETWORKID \
	--port $PORT $NAT \
	--rpc \
	--rpcaddr "0.0.0.0" \
	--cache "16" \
	--minerthreads 1 \
	--mine \
	--etherbase $ETHERBASE \
	--bootnodes self

