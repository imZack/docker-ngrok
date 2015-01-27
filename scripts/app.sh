#!/bin/bash

set -e

DOMAIN=${DOMAIN:-my.domain.com}
HTTP_ADDR=${HTTP_ADDR:-80}
HTTPS_ADDR=${HTTPS_ADDR:-443}
TUNNEL_ADDR=${TUNNEL_ADDR:-4443}
ARCH=${ARCH:-linux_amd64}
EXT=""
if [ $ARCH == windows_386 ] || [ $ARCH == windows_amd64 ]; then
	EXT=".exe"
fi
BUILD=0

function build_ngrok {
	git clone https://github.com/inconshreveable/ngrok.git /tmp/ngrok

	cd /tmp/ngrok

	cp /data/crt/rootCA.pem assets/client/tls/ngrokroot.crt

	GOOS=linux GOARCH=arm make release-server release-client
	GOOS=linux GOARCH=amd64 make release-server release-client
	GOOS=linux GOARCH=386 make release-server release-client
	GOOS=windows GOARCH=386 make release-server release-client
	GOOS=windows GOARCH=amd64 make release-server release-client

	cp -r /tmp/ngrok/bin /data

	mkdir -p /data/bin/linux_amd64
	ln -s /data/bin/ngrok /data/bin/linux_amd64/ngrok || true
	ln -s /data/bin/ngrokd /data/bin/linux_amd64/ngrokd || true
}

function gen_crt {
	mkdir -p /data/crt || true
	cd /data/crt

	openssl genrsa -out rootCA.key 2048
	openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$DOMAIN" -days 5000 -out rootCA.pem
	openssl genrsa -out device.key 2048
	openssl req -new -key device.key -subj "/CN=$DOMAIN" -out device.csr
	openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
}

if [ $# -lt 1 ]
then
    echo "Usage : $0 <command>"
    echo "    start, init, getclient, getserver, getcrt"
    exit
fi

if [ ! -f /data/bin/ngrokd ] || [ ! -f /data/bin/ngrok ]; then
	echo "Binaries not found. Start generating..."
	gen_crt
	build_ngrok
	BUILD=1
	echo "Done."
fi

case "$1" in
init)
	if [ $BUILD == 1 ]; then
		exit 0
	fi
	gen_crt
	build_ngrok
	;;
start)
	exec /data/bin/ngrokd \
		-tlsKey=/data/crt/device.key \
		-tlsCrt=/data/crt/device.crt \
		-domain="$DOMAIN" \
		-httpAddr=":$HTTP_ADDR" \
		-httpsAddr=":$HTTPS_ADDR" \
		-tunnelAddr=":$TUNNEL_ADDR"
	;;
getclient)
	cat /data/bin/$ARCH/ngrok$EXT
	;;
getserver)
	cat /data/bin/$ARCH/ngrokd$EXT
	;;
esac
