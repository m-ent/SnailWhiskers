#!/bin/sh
bundle exec rake db:create RACK_ENV=test
bundle exec rake db:migrate RACK_ENV=test
