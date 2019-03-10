#!/bin/bash

[ -f "/vagant/install.sh" ] && (
    /vagant/prepare.sh $1 $2
) || echo "not install"