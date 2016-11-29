FROM buildpack-deps:xenial-curl
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

RUN apt-get update \
    && apt-get install -y apt-transport-https \
    && curl -sL https://syncthing.net/release-key.txt | apt-key add - \
    && echo "deb https://apt.syncthing.net/ syncthing release" >> \
        /etc/apt/sources.list.d/syncthing.list \
    && apt-get update \
    && apt-get install -y syncthing \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

EXPOSE 8384 22000 21027/udp

COPY init config.xml /

CMD ["/init"]
