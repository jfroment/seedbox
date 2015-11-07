FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

RUN curl -sL "https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu&X-Plex-Token=" > /tmp/plex.deb && \
    dpkg -i /tmp/plex.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY plexmediaserver /etc/default/plexmediaserver
COPY start Preferences.xml /

VOLUME /config
EXPOSE 32400

CMD ["/start"]
