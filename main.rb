require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/activerecord'

require './models'

class Main < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    'Welcome abord'
  end

  get '/patients' do
    @patients = Patient.all
    erb :patients_index
  end
end

