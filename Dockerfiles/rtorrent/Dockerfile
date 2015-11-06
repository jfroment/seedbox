FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        rtorrent \
        php5-fpm \
        php5-cli \
        php5-geoip \
        mediainfo && \
    ln -s /config/rtorrent/rtorrent.rc ~/.rtorrent.rc && \
    git clone --depth=1 https://github.com/Novik/ruTorrent.git /opt/rutorrent && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config /torrents
COPY start rtorrent.rc supervisord.conf /
COPY nginx.conf /etc/nginx/nginx.conf
COPY rutorrent_config.php /opt/rutorrent/conf/config.php
EXPOSE 80 49161 49161/udp 6881/udp

CMD ["/start"]
