FROM ubuntu:trusty
MAINTAINER Jean Froment <froment.je@gmail.com>

RUN apt-get update && apt-get install -y nginx php5-fpm supervisor wget unzip patch

# download latest release
RUN wget http:`(wget https://larsjung.de/h5ai/ -q -O -) | sed 's/.*href="\(.*\.zip\)".*/\1/p' | head -n1`
RUN unzip h5ai-*.zip -d /usr/share/h5ai

ADD h5ai.nginx.conf /etc/nginx/sites-available/default

VOLUME /torrents

ADD h5ai-path.patch patch
RUN patch -p1 -u -d /usr/share/h5ai/_h5ai/private/php/core/ -i /patch && rm patch

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD supervisord -c /etc/supervisor/conf.d/supervisord.conf

EXPOSE 12333