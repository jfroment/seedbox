FROM buildpack-deps:xenial-scm
MAINTAINER Jean Froment <froment.je@gmail.com>

RUN apt-get update; apt-get install -y \
    deluged \
    deluge-web

ADD entrypoint.sh /opt/entrypoint.sh
RUN chmod a+x /opt/entrypoint.sh

VOLUME /config
VOLUME /torrents

EXPOSE 8112 58846 53160 53160/udp

CMD ["/opt/entrypoint.sh"]