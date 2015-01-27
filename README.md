ngrok for Docker
================
Self-hosting ngrok service

[![](http://dockeri.co/image/zack/docker-ngrok)](https://registry.hub.docker.com/u/zack/docker-ngrok/)

Step by Step
------------

- 1. Setup ENV & Create a data container:
```
  $ export NGROK_DATA=ngrok-data
  $ export DOMAIN=t.yulun.me
  $ export TUNNEL_ADDR=443
  $ docker run -v /data --name $NGROK_DATA busybox
```

- 2. Run init script from image:
```
  $ docker run --name ngrokd --rm --volumes-from $NGROK_DATA \
    -p 80:80 -p 4443:4443 -p 443:443 \
    -e HTTPS_ADDR=80 -e HTTPS_ADDR=4443 -e TUNNEL_ADDR=$TUNNEL_ADDR -e DOMAIN=$DOMAIN \
    zack/docker-ngrok
```

wait for a while...
```
  [01/27/15 16:26:04] [INFO] [registry] [tun] No affinity cache specified
  [01/27/15 16:26:04] [INFO] [metrics] Reporting every 30 seconds
  [01/27/15 16:26:05] [INFO] Listening for public http connections on [::]:80
  [01/27/15 16:26:05] [INFO] Listening for public https connections on [::]:4443
  [01/27/15 16:26:05] [INFO] Listening for control and proxy connections on [::]:443
```

- 3. Get clients by arch

**ARCH** could be one of `linux_amd64, linux_386, linux_arm, windows_386, windows_amd64`
```
  $ docker run --name ngrokd --rm --volumes-from $NGROK_DATA \
    -e ARCH=linux_amd64 zack/docker-ngrok getclient >ngrok
```

- 4. On other machines (clients), Setup and Start

```
  $ echo "server_addr: $DOMAIN:$TUNNEL_ADDR\ntrust_host_root_certs: false" > `pwd`/ngrok.yml
  $ ./ngrok -config=`pwd`/ngrok.yml
```

License
-------
[MIT](http://yulun.mit-license.org/)
