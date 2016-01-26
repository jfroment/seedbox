FROM kelvinchen/seedbox:base
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

RUN apt-get update \
    && apt-get install --no-install-recommends -y python-cheetah \
    && git clone --depth=1 \
        https://github.com/SickRage/SickRage.git \
        /opt/sickrage \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

VOLUME /config

EXPOSE 8081

CMD python /opt/sickrage/SickBeard.py --nolaunch --datadir \
    /config/sickrage >> /dev/null 2>&1
