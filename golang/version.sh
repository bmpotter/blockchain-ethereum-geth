#!/bin/bash

curl -sL https://github.com/golang/go/releases | grep tag-name | head -1 | perl -p -e 's/.*go([0-9\.]+)<.*/\1/'
