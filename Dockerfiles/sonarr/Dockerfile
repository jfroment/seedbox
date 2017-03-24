FROM buildpack-deps:xenial-scm
MAINTAINER Jean Froment <froment.je@gmail.com>

# Get latest path for Jackett
RUN jack_tag=$(curl -sX GET "https://api.github.com/repos/Jackett/Jackett/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]') \

# Install Sonarr, S6, and Jackett
    && echo "deb http://apt.sonarr.tv/ master main" \
            > /etc/apt/sources.list.d/sonarr.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
    && apt-get update \
    && apt-get install -y nzbdrone libcurl4-openssl-dev mono-devel \
    && curl -sL "https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz" \
        | tar xz -C / \
    && curl -sL "https://github.com/Jackett/Jackett/releases/download/$jack_tag/Jackett.Binaries.Mono.tar.gz" \
        | tar xz -C /opt \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set Jackett config path
ENV XDG_DATA_HOME="/config" \
    XDG_CONFIG_HOME="/config"

VOLUME /config

# 8989 is Sonarr, 9117 is Jackett
EXPOSE 8989 9117

COPY services.d /etc/services.d

CMD ["/init"]
