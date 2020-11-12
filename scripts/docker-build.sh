#!/bin/bash
set -euf -o pipefail
if [[ "$#" == "1" && "$1" == "go" ]]; then
	export DEBIAN_FRONTEND=noninteractive
	cd /mnt

	apt-get update
	ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
	apt-get install -y wget --no-install-suggests
	dpkg -i scripts/netpbm-sf-10.73.33_amd64.deb || echo "Fixing up next"
	apt-get install -y -f --no-install-suggests
	apt-get install -y --no-install-suggests python3 python3-pip nasm
	pip3 install amitools
	make.sh
else
	docker run --rm -v "`pwd`":/mnt ubuntu /mnt/scripts/docker-build.sh go
fi
