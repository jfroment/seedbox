FROM buildpack-deps:xenial-curl
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install OpenVPN
RUN curl -sL "https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz" \
        | tar xz -C / \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        openvpn \
        easy-rsa \
        iptables \
        bridge-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /usr/share/easy-rsa

EXPOSE 1194/udp

VOLUME /config

COPY container-root/ /

CMD ["/init"]
