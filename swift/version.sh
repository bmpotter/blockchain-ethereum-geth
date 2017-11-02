#!/bin/bash

curl -sL https://pypi.python.org/pypi/python-swiftclient | grep python-swiftclient | grep title | head -1 | awk '{print $2}'
