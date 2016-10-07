FROM ubuntu:xenial
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install OpenVPN
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openvpn \
        easy-rsa \
        iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /usr/share/easy-rsa

EXPOSE 1194/udp

VOLUME /config

COPY vars /usr/share/easy-rsa/
COPY openvpn.conf init client.ovpn /
COPY export-client /usr/local/bin/

CMD ["/init"]
