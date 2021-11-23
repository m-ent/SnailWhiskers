ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

include Rack::Test::Methods

def app
  Main
end
