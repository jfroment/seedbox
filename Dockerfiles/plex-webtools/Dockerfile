FROM buildpack-deps:xenial-scm
MAINTAINER Jean Froment <froment.je@gmail.com>

RUN apt-get update \
	&& apt-get install -y unzip libcurl4-openssl-dev \
	&& wt_tag=$(curl -sX GET "https://api.github.com/repos/ukdtom/WebTools.bundle/releases/latest" \
    	| awk '/tag_name/{print $4;exit}' FS='[""]') \
	&& wget "https://github.com/ukdtom/WebTools.bundle/releases/download/$wt_tag/WebTools.bundle.zip" \
    	-O /opt/WebTools.bundle.zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /config

RUN mkdir -p "/config/Plex Media Server/" \
	&& cp /opt/WebTools.bundle.zip /config/Plex\ Media\ Server/ \
	&& unzip /config/Plex\ Media\ Server/WebTools.bundle.zip \
	&& rm -f /opt/WebTools.bundle.zip /config/Plex\ Media\ Server/WebTools.bundle.zip

EXPOSE 33443
