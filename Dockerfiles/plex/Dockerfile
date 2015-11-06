FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

ARG PLEX_VER=0.9.12.18.1520-6833552
ARG PLEX_DL="https://downloads.plex.tv/plex-media-server/$PLEX_VER/plexmediaserver_${PLEX_VER}_amd64.deb"

RUN curl -sL "$PLEX_DL" > /tmp/plex.deb && \
    dpkg -i /tmp/plex.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY plexmediaserver /etc/default/plexmediaserver
COPY start Preferences.xml /

VOLUME /config
EXPOSE 32400

CMD ["/start"]
