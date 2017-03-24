FROM nginx:1.11-alpine
MAINTAINER Jean Froment <froment.je@gmail.com>

RUN apk add --no-cache apache2-utils openssl

VOLUME /config

EXPOSE 80 443

ENV USERNAME=user \
    PASSWORD=h4ckMePleAse \
    USE_SSL=true

COPY nginx.conf common_default.conf ssl.conf /etc/nginx/
COPY init /
COPY ssl-gen /usr/local/bin

CMD ["/init"]
