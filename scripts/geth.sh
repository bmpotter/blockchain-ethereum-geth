#!/bin/bash

. $(dirname $0)/functions

(
geth_account
geth_getblocks
PEERS=$(geth_getpeers)
NETWORKID=$(geth_getnetworkid)
geth_getdiraddr
geth_getgenesis
geth_init
geth_process $NETWORKID $PEERS
) 2>&1 | sed -u 's/^/GETH: /'

