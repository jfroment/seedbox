FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install all dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        rtorrent \
        php5-fpm \
        php5-cli \
        php5-geoip \
        mediainfo \
        irssi \
        libxml-libxml-perl \
        libxml-libxslt-perl \
        libjson-perl \
        libjson-xs-perl \
        libnet-ssleay-perl \
        libdigest-perl \
        libdigest-sha-perl \
        libhtml-parser-perl \
        libarchive-zip-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure/install r(u)torrent and autodl-irssi
RUN ln -s /config/rtorrent/rtorrent.rc ~/.rtorrent.rc \
    && git clone --depth=1 \
        https://github.com/Novik/ruTorrent.git \
        /opt/rutorrent \
    && git clone --depth=1 --recursive \
        https://github.com/autodl-community/autodl-irssi.git \
        ~/.irssi/scripts \
    && mkdir -p ~/.irssi/scripts/autorun \
    && cp ~/.irssi/scripts/autodl-irssi.pl ~/.irssi/scripts/autorun \
    && ln -s /config/autodl/ ~/.autodl \
    && sed -i "s/www-data/root/g" /etc/php5/fpm/pool.d/www.conf

VOLUME /config /torrents

EXPOSE 80 49161 49161/udp 6881/udp

COPY start rtorrent.rc supervisord.conf autodl.cfg /
COPY nginx.conf /etc/nginx/nginx.conf
COPY rutorrent_config.php /opt/rutorrent/conf/config.php
COPY irssi.cfg /root/.irssi/config

CMD ["/start"]
