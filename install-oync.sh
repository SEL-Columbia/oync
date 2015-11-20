#!/bin/bash

# * assumes these are already installed via Dockerfile
# setup libs for ruby 
# apt-get -y install curl build-essential ruby ruby-dev zlib1g-dev libpq-dev postgresql

# install gems
# * assumes workdir is oync which has been created with Gemfiles added via Dockerfile
gem install bundler
bundle install
