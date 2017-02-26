require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/activerecord'

require './models'
require './helpers'

class Main < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  configure :development do
    register Sinatra::Reloader
  end

  helpers do
    include Helpers
  end

  get '/' do
    'Welcome abord'
  end

  get '/patients' do # patients#index
    @patients = Patient.all
    erb :patients_index
  end

  get '/patients/:id' do # patients#show
    @patient = Patient.find(params[:id])
    erb :patients_show
  end
end

