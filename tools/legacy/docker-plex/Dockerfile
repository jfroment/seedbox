FROM buildpack-deps:xenial-scm

# Download plexupdate script and install Plex
# This script can be later used to update Plex directly in the container
RUN curl -sL "https://github.com/mrworf/plexupdate/raw/master/plexupdate.sh" \
        > /usr/local/bin/plexupdate \
    && chmod +x /usr/local/bin/plexupdate \
    && plexupdate -pad \
    && apt-get update \
    && apt-get install -y unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

# 32400 for Plex server, 33443 for Plex WebTools secure access
EXPOSE 32400 33443

COPY plexmediaserver /etc/default/plexmediaserver
COPY init Preferences.xml /

CMD ["/init"]
