#!/bin/bash

curl --speed-limit 1 --speed-time 30 -sL http://127.0.0.1:$RPCPORT -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' | jq -r '.result[]|.name,.network.remoteAddress' | paste -d " " - - # sed 'N;s/\n/ /'

