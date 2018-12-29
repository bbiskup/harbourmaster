FROM ubuntu:16.04

MAINTAINER Bernhard Biskup <bbiskup@gmx.de>

ENV DEBIAN_FRONTEND noninteractive
ENV NODE_DIR=node-v6.2.0-linux-x64
ENV NODE_ARCHIVE=$NODE_DIR.tar.xz
ENV PATH=/opt/node/bin:$PATH

RUN apt-get -q -y update && apt-get install -y wget 

# Install Google Chrome APT repository
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

RUN apt-get -q -y update && apt-get install -y \
        curl \
        dbus-x11 \
        default-jre-headless \
        google-chrome-stable \
        make \
        python3 \
        python3-pip \
        python3-dev \
        software-properties-common \
        xvfb \
    && rm -rf /var/lib/apt/lists/*


# To avoid chrome waiting for gnome keyring
ENV DBUS_SESSION_BUS_ADDRESS /dev/null
RUN dpkg -r libfolks-eds25 gnome-keyring seahorse gcr evolution-data-server oneconf python-ubuntuone-storageprotocol ubuntu-sso-client python-ubuntu-sso-client pinentry-gnome3

# Install node.js; use most recent version to have access to latest features
WORKDIR /opt
RUN wget -q https://nodejs.org/dist/v6.2.0/$NODE_ARCHIVE && \
    tar xJf $NODE_ARCHIVE && \
    ln -s /opt/$NODE_DIR /opt/node && \
    rm $NODE_ARCHIVE
WORKDIR /code
RUN node --version
RUN npm --version

RUN npm install -g elm
RUN npm install -g elm-test

RUN pip3 install pipenv

# Use UTF-8 locale (required by Python library 'Click')
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

