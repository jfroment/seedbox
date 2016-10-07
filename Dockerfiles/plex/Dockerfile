FROM buildpack-deps:xenial-scm
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Download plexupdate script and install Plex
# This script can be later used to update Plex directly in the container
RUN curl -sL "https://github.com/mrworf/plexupdate/raw/master/plexupdate.sh" \
        > /usr/local/bin/plexupdate \
    && chmod +x /usr/local/bin/plexupdate \
    && plexupdate -pad \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

EXPOSE 32400

COPY plexmediaserver /etc/default/plexmediaserver
COPY init Preferences.xml /

CMD ["/init"]
