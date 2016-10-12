FROM buildpack-deps:xenial-scm
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install Sonarr, S6, and Jackett
RUN echo "deb http://apt.sonarr.tv/ master main" \
        > /etc/apt/sources.list.d/sonarr.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
    && apt-get update \
    && apt-get install -y nzbdrone libcurl4-openssl-dev \
    && curl -sL "https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz" \
        | tar xz -C / \
    && curl -sL "https://github.com/Jackett/Jackett/releases/download/v0.7.420/Jackett.Binaries.Mono.tar.gz" \
        | tar xz -C /opt \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set Jackett config path
ENV XDG_DATA_HOME="/config" \
    XDG_CONFIG_HOME="/config"

VOLUME /config

EXPOSE 8989 9117

COPY services.d /etc/services.d

CMD ["/init"]
