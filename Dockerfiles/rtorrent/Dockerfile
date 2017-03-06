FROM buildpack-deps:xenial-scm
MAINTAINER Jean Froment <froment.je@gmail.com>

# For rtorrent
ENV TERM=xterm

# Install dependencies
RUN curl -sL "https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz" \
        | tar xz -C / \
    && apt-get update \
    && apt-get install -y \
        screen \
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

COPY container-root/ /

CMD ["/init"]
