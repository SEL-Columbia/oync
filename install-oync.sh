#!/bin/bash
# setup libs for oync
apt-get -y install curl build-essential ruby ruby-dev zlib1g-dev
gem install bundler
bundle install
