FROM lsiobase/alpine.python:3.6
MAINTAINER fromenje

# set python to use utf-8 rather than ascii.
ENV PYTHONIOENCODING="UTF-8"

# install app
RUN \
 git clone --depth 1 https://github.com/CouchPotato/CouchPotatoServer /app/couchpotato

# add local files
COPY root/ /

# ports and volumes
EXPOSE 5050
WORKDIR /app/couchpotato
VOLUME /config /downloads /movies
