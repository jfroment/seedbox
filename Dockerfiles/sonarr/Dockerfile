FROM buildpack-deps:xenial-scm
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install Sonarr
RUN echo "deb http://apt.sonarr.tv/ master main" \
        > /etc/apt/sources.list.d/sonarr.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
    && apt-get update \
    && apt-get install -y nzbdrone \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

VOLUME /config

EXPOSE 8989

COPY init /

CMD ["/init"]
