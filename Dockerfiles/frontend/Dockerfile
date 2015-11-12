FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

RUN apt-get update \
    && apt-get install --no-install-recommends -y apache2-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

EXPOSE 80 443

ENV USERNAME=user \
    PASSWORD=hunter2 \
    USE_SSL=false

COPY nginx.conf common_default.conf ssl.conf /etc/nginx/
COPY start /
COPY ssl-gen /usr/local/bin

CMD ["/start"]
