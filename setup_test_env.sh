#!/bin/sh
bundle exec rake db:migrate RACK_ENV=test
