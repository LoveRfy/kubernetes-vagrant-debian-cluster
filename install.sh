#!/bin/bash

[ -f "/vagrant/install.sh" ] && (
    /vagrant/prepare.sh $1 $2
) || echo "not install"