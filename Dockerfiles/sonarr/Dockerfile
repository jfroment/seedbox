FROM buildpack-deps:xenial-scm
MAINTAINER Jean Froment <froment.je@gmail.com>

# Install Sonarr, S6, and Jackett
RUN echo "deb http://apt.sonarr.tv/ master main" \
        > /etc/apt/sources.list.d/sonarr.list \
    && echo "deb http://download.mono-project.com/repo/ubuntu xenial main" \
        > /etc/apt/sources.list.d/mono.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && apt-get update \
    && apt-get install -y mono-complete nzbdrone libcurl4-openssl-dev \
    && curl -sL "https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz" \
        | tar xz -C / \
    && curl -sL $(curl -sL https://api.github.com/repos/Jackett/Jackett/releases | grep browser_download_url | grep Mono | head -n 1 | cut -d '"' -f 4) \
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
