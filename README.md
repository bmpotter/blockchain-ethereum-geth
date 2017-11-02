## geth container

### Build

```
make 
```

OR

```
make TAG=1.4.18 # optional TAG for specific geth version, otherwise defaults to latest
```

### Client Run (for Horizon bootstrap)

```
export INSTANCE_NAME=client
export LOCAL_DATA_DIR=/ssd/geth_root_user
export LOCAL_PORT=8545
export RAM=128m # for 1GB system
mkdir -p $LOCAL_DATA_DIR
docker run -m $RAM -d -t --name $INSTANCE_NAME -v $LOCAL_DATA_DIR:/root -p 127.0.0.1:$LOCAL_PORT:8545 $(uname -m)/geth start.sh
```

> NOTE: `-p 127.0.0.1:$LOCAL_PORT:8545` limits RPC access to localhost only, be careful with this.

> NOTE: If running more than a single instance, then you must have different `$INSTANCE_NAME`, `$LOCAL_DATA_DIR`, and `$LOCAL_PORT` variables.


### Miner Run
```
export INSTANCE_NAME=miner
export LOCAL_DATA_DIR=/ssd/geth_root_user
export LOCAL_PORT=8545
export EXTNIC=eth0
export EXTIP=$(ip addr show dev $EXTNIC | grep 'inet ' | awk '{print $2}' | awk -F/ '{print $1}')
export PORT=30303
mkdir -p $LOCAL_DATA_DIR
# Run only once!  A 2nd run will destroy your chain.
docker run --rm -it --name $INSTANCE_NAME -v $LOCAL_DATA_DIR:/root -p 127.0.0.1:$LOCAL_PORT:8545 $(uname -m)/geth genesis.sh
# Can kill and restart without issue
docker run -d -t --name $INSTANCE_NAME -v $LOCAL_DATA_DIR:/root -p 127.0.0.1:$LOCAL_PORT:8545 -p $PORT:$PORT -p $PORT:$PORT/udp -e EXTIP=$EXTIP $(uname -m)/geth miner.sh
```

> NOTE: `-p 127.0.0.1:$LOCAL_PORT:8545` limits RPC access to localhost only, be careful with this.

> NOTE: If running more than a single instance, then you must have different `$INSTANCE_NAME`, `$LOCAL_DATA_DIR`, `$LOCAL_PORT`, and `$PORT` variables.

You'll need the enode and network ID from the miner to peer with it, e.g.:
```
curl -sL http://127.0.0.1:8545 -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' | jq -r '.result.protocols.eth.network'
913172220

# curl -sL http://127.0.0.1:8545 -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' | jq -r '.result.enode'
enode://12f518053bc6a8c54cb9c26c1948cdadece60988a6bfb5423038c4ed14252f132eb02202f541fb83457d0e81c8ecb42bf7ea2588a78f1990a96f9620e6c52990@199.88.179.63:30303
```

### Client Run (hack for adhoc miner)
```
cp geth.sh gethadhoc.sh
mkdir -p /root/.colonus # put genesis.json in here from $EXTIP:$LOCAL_DATA_DIR above
```

Optional pre-gen account setup:
```
mkdir -p /root/.ethereum/keystore
# copy from from $EXTIP:$LOCAL_DATA_DIR above accountN, keydataN.b64, keynameN.b64, and passwdN to /tmp
# e.g. for N = 1
cp /tmp/account1 /root/.colonus/accounts 
cp /tmp/passwd1 /root/.colonus/passwd 
base64 -d /tmp/keydata1.b64 >/root/.ethereum/keystore/$(base64 -d /tmp/keyname1.b64)
```

Edit `gethadhoc.sh` to look like this using the enode and network ID from above:
```
#!/bin/bash

. $(dirname $0)/functions

(
geth_account
PEERS=enode://12f518053bc6a8c54cb9c26c1948cdadece60988a6bfb5423038c4ed14252f132eb02202f541fb83457d0e81c8ecb42bf7ea2588a78f1990a96f9620e6c52990@199.88.179.63:30303
NETWORKID=913172220
geth_init
geth_process $NETWORKID $PEERS
) 2>&1 | sed -u 's/^/GETH: /'
```

Run:
```
./handout.sh & ./unlock.sh & ./blockmon.sh & ./gethadhoc.sh
```

> NOTE: `./handout.sh` will do nothing since there is no ATM with this setup.  Use a pre-gen account or manually xfer funds.

### Debug
```
docker logs -f $INSTANCE_NAME
```

### Stop
```
docker rm -f $INSTANCE_NAME
```
