FROM buildpack-deps:xenial-scm
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install dependencies
RUN apt-get update \
    && apt-get install -y \
        supervisor \
        rtorrent \
        mediainfo \
        php7.0-fpm \
        php7.0-cli \
        nginx \
        unrar-free \
        unzip \
        ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure/install r(u)torrent
RUN ln -s /config/rtorrent/rtorrent.rc ~/.rtorrent.rc \
    && mkdir -p /var/run/php \
    && git clone --depth=1 \
        https://github.com/Novik/ruTorrent.git \
        /opt/rutorrent \
    && sed -i "s/www-data/root/g" /etc/php/7.0/fpm/pool.d/www.conf

VOLUME /config /torrents

EXPOSE 80 49161 49161/udp 6881/udp

COPY init rtorrent.rc supervisord.conf /
COPY nginx.conf /etc/nginx/nginx.conf
COPY rutorrent_config.php /opt/rutorrent/conf/config.php

CMD ["/init"]
