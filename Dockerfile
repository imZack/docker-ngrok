FROM debian:stable

MAINTAINER YuLun Shih <shih@yulun.me>

RUN apt-get update -y && \
	apt-get install --no-install-recommends -y -q curl \
		build-essential ca-certificates git mercurial 

RUN	curl -O -s https://storage.googleapis.com/golang/go1.4.1.src.tar.gz && \
	tar -xzf go1.4.1.src.tar.gz -C /usr/local && \
	cd /usr/local/go/src && ./make.bash --no-clean 2>&1

ENV PATH /usr/local/go/bin:$PATH

ENV GOPATH /gopath

ADD ./scripts /scripts

VOLUME ["/data"]

ENTRYPOINT ["/scripts/app.sh"]

CMD ["start"]