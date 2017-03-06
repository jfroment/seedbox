FROM ubuntu:14.04
MAINTAINER Jean Froment <froment.je@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV H5AI_VERSION 0.29.0
ENV HTTPD_USER www-data

RUN apt-get update && apt-get install -y \
  nginx php5-fpm supervisor \
  wget unzip patch acl \
  libav-tools imagemagick \
  graphicsmagick zip unzip php5-gd

# install h5ai and patch configuration
RUN wget http://release.larsjung.de/h5ai/h5ai-$H5AI_VERSION.zip
RUN unzip h5ai-$H5AI_VERSION.zip -d /usr/share/h5ai

# patch h5ai because we want to deploy it ouside of the document root and use /var/www as root for browsing
COPY class-setup.php.patch class-setup.php.patch
RUN patch -p1 -u -d /usr/share/h5ai/_h5ai/private/php/core/ -i /class-setup.php.patch && rm class-setup.php.patch

RUN rm /etc/nginx/sites-enabled/default

#make the cache writable
RUN chown ${HTTPD_USER} /usr/share/h5ai/_h5ai/public/cache/
RUN chown ${HTTPD_USER} /usr/share/h5ai/_h5ai/private/cache/

# use supervisor to monitor all services
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD supervisord -c /etc/supervisor/conf.d/supervisord.conf

# expose only nginx HTTP port
EXPOSE 12333