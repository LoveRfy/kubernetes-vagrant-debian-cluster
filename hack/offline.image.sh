#!/bin/bash

docker images | grep "ago" | awk '{print $1":"$2}' > /tmp/offimage.txt

cat /tmp/offimage.txt | while read line
do
	pkg=$(echo ${line##*/} | tr ':' '.')
	docker save $line > ./$pkg.tgz
done

tar zcf /vagrant/pkg.tgz `find . -maxdepth 1 -iname "*.tgz"`