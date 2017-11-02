#!/bin/bash

export N_ACCT=${N_ACCT:=4}
export BALANCE=${BALANCE:=1000000000000000000000000000000}
export KDF=${KDF:=--lightkdf}
export NETWORKID=${NETWORKID:=$(echo $(( 0x$(openssl rand -hex 4) )))}

# init and create accounts
cd /root
rm -rf .ethereum .ethash
mkdir -p .ethereum # to avoid geth y/N question

echo $NETWORKID >/root/networkid

# create genesis block
cat >genesis.json <<EOF
{
    "nonce": "0x0000000000000042",
    "difficulty": "0x000000100",
    "alloc": {
EOF

COMMA=","
for i in $(seq 0 $N_ACCT)
do
	PASSWD=${PASSWD:=$(tr -dc _A-Za-z0-9 < /dev/urandom | head -c32)}
	echo $PASSWD >/root/passwd$i
	ACCT=$(geth $KDF --password /root/passwd$i account new | perl -p -e 's/[{}]//g' | awk '{print $NF}')
	echo $ACCT >/root/account$i
	basename /root/.ethereum/keystore/*$ACCT | base64 -w 0 >/root/keyname$i.b64
	base64 -w 0 /root/.ethereum/keystore/*$ACCT >/root/keydata$i.b64

	if ((i == N_ACCT))
	then
		COMMA=""
	fi

cat >>genesis.json <<EOF
        "$ACCT": {
            "balance": "$BALANCE"
        }$COMMA
EOF

done

cat >>genesis.json <<EOF
    },
    "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "timestamp": "0x00",
    "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "gasLimit": "0x3ffffff"
}
EOF

base64 -w 0 /root/genesis.json >/root/genesis.b64

