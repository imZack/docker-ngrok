#!/bin/bash

set -e

DOMAIN=${DOMAIN:-my.domain.com}
HTTP_ADDR=${HTTP_ADDR:-80}
HTTPS_ADDR=${HTTPS_ADDR:-443}
TUNNEL_ADDR=${TUNNEL_ADDR:-4443}

function build_ngrok {
	git clone https://github.com/inconshreveable/ngrok.git /tmp/ngrok

	cd /tmp/ngrok

	cp /data/crt/rootCA.pem assets/client/tls/ngrokroot.crt

	make release-server release-client

	mkdir -p /data/bin || true
	cp /tmp/ngrok/bin/ngrok /tmp/ngrok/bin/ngrokd /data/bin/
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
	echo "Done."
fi

case "$1" in
init)
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
	cat /data/bin/ngrok
	;;
getserver)
	cat /data/bin/ngrokd
	;;
esac
