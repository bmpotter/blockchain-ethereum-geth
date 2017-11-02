#!/bin/bash

handout.sh &
unlock.sh &
blockmon.sh &

while :
do
	geth.sh
done
