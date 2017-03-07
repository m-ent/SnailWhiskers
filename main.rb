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
  enable :method_override

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

  get '/patients/new' do # patients#new
    erb :patients_new
  end

  get '/patients/:id' do # patients#show
    @patient = Patient.find(params[:id])
    erb :patients_show
  end

  post '/patients' do # patients#create
    @patient = Patient.new(params)
    if @patient.save
      redirect to("/patients/#{@patient.id}")
    else
      erb :patients_new
    end
  end

  get '/patients/:id/edit' do # patients#edit
    @patient = Patient.find(params[:id])
    erb :patients_edit
  end

  put '/patients/:id' do # patient#update
    @patient = Patient.find(params[:id])
    if @patient.update(select_params(params, [:hp_id]))
      redirect to("/patients/#{@patient.id}")
    else
      erb :patients_edit
    end
  end

  delete '/patients/:id' do # patients#destroy
    @patient = Patient.find(params[:id])
    @patient.destroy
    redirect to("/patients")
  end

  get '/patients/by_hp_id/:hp_id' do #patients#by_hp_id
    if valid_id?(params[:hp_id]) 
      @patient = Patient.where(hp_id: params[:hp_id]).take
      if @patient
        redirect to("/patients/#{@patient.id}")
      else
        404  # not found
      end
    else
      400  # bad request
    end
  end

  private
  def select_params(params, keys)
    h = Hash.new
    keys.each do |key|
      h[key] = params[key]
    end
    return h
  end
end

