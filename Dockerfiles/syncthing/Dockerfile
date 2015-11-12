FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

RUN curl -sL https://syncthing.net/release-key.txt | apt-key add - \
    && echo "deb http://apt.syncthing.net/ syncthing release" >> \
        /etc/apt/sources.list.d/syncthing.list \
    && apt-get update \
    && apt-get install syncthing \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

EXPOSE 8384 22000 21027/udp

COPY start config.xml /

CMD ["/start"]
