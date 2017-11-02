#!/bin/bash

IMAGE=$1
ARCH=$3
TAG=$3

if docker inspect ${ARCH}/${IMAGE}:${TAG} >/dev/null 2>&1
then
	TZ=GMT touch -t $(docker inspect -f '{{ .Created }}' ${ARCH}/${IMAGE}:${TAG} | awk -F. '{print $1}' | sed 's/[-T]//g' | sed 's/://' | sed 's/:/./') ${IMAGE}-${ARCH}-${TAG}.flag
else
	rm -f ${IMAGE}-${ARCH}-${TAG}.flag
fi

