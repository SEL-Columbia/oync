#!/bin/bash
# setup libs that oync
apt-get -y install curl build-essential ruby-dev zlib1g-dev
gem install bundler
bundle install
