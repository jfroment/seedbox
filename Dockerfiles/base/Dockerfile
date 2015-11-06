FROM debian:jessie
MAINTAINER Kelvin Chen <kelvin@kelvinchen.org>

# Install all dependencies that are used in multiple images
# to avoid wasting space.
RUN echo "deb http://httpredir.debian.org/debian jessie non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        vim \
        ca-certificates \
        python \
        python-dev \
        curl \
        git \
        nginx \
        unzip \
        unrar \
        supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
