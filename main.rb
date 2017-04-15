require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/activerecord'

require './models'
require './helpers'
require './lib/audio_class'

class Main < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  configure do
    case settings.environment
    when :production
      ENV['RACK_ENV'] = "production"
    when :test
      ENV['RACK_ENV'] = "test"
    else
      ENV['RACK_ENV'] = "development"
    end
  end
  configure :development do
    register Sinatra::Reloader
  end
  enable :method_override

  Image_root = "assets/images"
  Thumbnail_size = "160x160"

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

  put '/patients/:id' do # patients#update
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

  get '/patients/by_hp_id/:hp_id' do # patients#by_hp_id
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

  get '/patients/:patient_id/audiograms' do # audiograms#index
    @patient = Patient.find(params[:patient_id])
    @audiograms = @patient.audiograms.order('examdate DESC').to_a
    erb :audiograms_index
  end

  get '/patients/:patient_id/audiograms/:id' do # audiograms#show
    @patient = Patient.find(params[:patient_id])
    @audiogram = @patient.audiograms.find(params[:id])
    app_root = File.dirname(__FILE__)
    image_root = "assets/images"
    if not File.exist?("#{app_root}/#{image_root}/#{@audiogram.image_location}") # imageがなければ作る
      build_graph
    end
    erb :audiograms_show
  end

#  get '/patients/:patient_id/audiograms/new' do # audiograms#new
#  end

#  post '/patients/:patient_id/audiograms' do # audiograms#create
#  end

#  get '/patients/:patient_id/audiograms/:id/edit' do # audiograms#edit
#  end

#  put '/patients/:patient_id/audiograms/:id' do # audiograms#update
#  end

#  delete '/patients/:patient_id/audiograms/:id' do # audiograms#destroy
#  end

  private
  def select_params(params, keys)
    h = Hash.new
    keys.each do |key|
      h[key] = params[key]
    end
    return h
  end

  def build_graph
    exam_year = @audiogram.examdate.strftime("%Y")
    base_dir = "#{ENV['RACK_ENV']}/graphs/#{exam_year}"
    @audiogram.image_location = make_filename(base_dir, \
                                @audiogram.examdate.getlocal.strftime("%Y%m%d-%H%M%S"))
    @audiogram.save
    thumbnail_location = @audiogram.image_location.sub("graphs", "thumbnails")
    image_root_env = "#{Image_root}/#{ENV['RACK_ENV']}"
    create_dir_if_not_exist("#{image_root_env}/graphs/#{exam_year}")
    create_dir_if_not_exist("#{image_root_env}/thumbnails/#{exam_year}")

    a = Audio.new(convert_to_audiodata(@audiogram))
    output_file = "#{Image_root}/#{@audiogram.image_location}"
    a.draw(output_file) # a.draw(filename)に変更されている
    system("convert -geometry #{Thumbnail_size} #{output_file} \
      #{Image_root}/#{thumbnail_location}") ### convert to 160x160px thumbnail
  end

  def make_filename(base_dir, base_name)
    # assume make_filename(base_dir, @audiogram.examdate.strftime("%Y%m%d-%H%M%S"))
    # as actual argument
    ver = 0
    Dir.glob("#{base_dir}/#{base_name}*").each do |f|
      if /#{base_name}.png\Z/ =~ f
        ver = 1 if ver == 0
      end
      if /#{base_name}-(\d*).png\Z/ =~ f
        ver = ($1.to_i + 1) if $1.to_i >= ver
      end
    end
    if ver == 0
      return "#{base_dir}/#{base_name}.png"
    else
      if ver < 100
        ver_str = "%02d" % ver
      else
        ver_str = ver.to_s
      end
      return "#{base_dir}/#{base_name}-#{ver_str}.png"
    end
  end

  def create_dir_if_not_exist(dir)
    FileUtils.makedirs(dir) if not File.exists?(dir)
  end

  def convert_to_audiodata(audiogram)
    ra_data = [{:data => audiogram.ac_rt_125, :scaleout => audiogram.ac_rt_125_scaleout},
               {:data => audiogram.ac_rt_250, :scaleout => audiogram.ac_rt_250_scaleout},
               {:data => audiogram.ac_rt_500, :scaleout => audiogram.ac_rt_500_scaleout},
               {:data => audiogram.ac_rt_1k,  :scaleout => audiogram.ac_rt_1k_scaleout} ,
               {:data => audiogram.ac_rt_2k,  :scaleout => audiogram.ac_rt_2k_scaleout} ,
               {:data => audiogram.ac_rt_4k,  :scaleout => audiogram.ac_rt_4k_scaleout} ,
               {:data => audiogram.ac_rt_8k,  :scaleout => audiogram.ac_rt_8k_scaleout} ]
    la_data = [{:data => audiogram.ac_lt_125, :scaleout => audiogram.ac_lt_125_scaleout},
               {:data => audiogram.ac_lt_250, :scaleout => audiogram.ac_lt_250_scaleout},
               {:data => audiogram.ac_lt_500, :scaleout => audiogram.ac_lt_500_scaleout},
               {:data => audiogram.ac_lt_1k,  :scaleout => audiogram.ac_lt_1k_scaleout} ,
               {:data => audiogram.ac_lt_2k,  :scaleout => audiogram.ac_lt_2k_scaleout} ,
               {:data => audiogram.ac_lt_4k,  :scaleout => audiogram.ac_lt_4k_scaleout} ,
               {:data => audiogram.ac_lt_8k,  :scaleout => audiogram.ac_lt_8k_scaleout} ]
    rb_data = [{:data => nil, :scaleout => nil},           # nil is better than "" ?
               {:data => audiogram.bc_rt_250, :scaleout => audiogram.bc_rt_250_scaleout},
               {:data => audiogram.bc_rt_500, :scaleout => audiogram.bc_rt_500_scaleout},
               {:data => audiogram.bc_rt_1k,  :scaleout => audiogram.bc_rt_1k_scaleout} ,
               {:data => audiogram.bc_rt_2k,  :scaleout => audiogram.bc_rt_2k_scaleout} ,
               {:data => audiogram.bc_rt_4k,  :scaleout => audiogram.bc_rt_4k_scaleout} ,
               {:data => audiogram.bc_rt_8k,  :scaleout => audiogram.bc_rt_8k_scaleout} ]
    lb_data = [{:data => nil, :scaleout => nil},           # nil is better than "" ?
               {:data => audiogram.bc_lt_250, :scaleout => audiogram.bc_lt_250_scaleout},
               {:data => audiogram.bc_lt_500, :scaleout => audiogram.bc_lt_500_scaleout},
               {:data => audiogram.bc_lt_1k,  :scaleout => audiogram.bc_lt_1k_scaleout} ,
               {:data => audiogram.bc_lt_2k,  :scaleout => audiogram.bc_lt_2k_scaleout} ,
               {:data => audiogram.bc_lt_4k,  :scaleout => audiogram.bc_lt_4k_scaleout} ,
               {:data => audiogram.bc_lt_8k,  :scaleout => audiogram.bc_lt_8k_scaleout} ]
    ra_mask = [{:type => audiogram.mask_ac_rt_125_type, :level => audiogram.mask_ac_rt_125},
               {:type => audiogram.mask_ac_rt_250_type, :level => audiogram.mask_ac_rt_250},
               {:type => audiogram.mask_ac_rt_500_type, :level => audiogram.mask_ac_rt_500},
               {:type => audiogram.mask_ac_rt_1k_type,  :level => audiogram.mask_ac_rt_1k} ,
               {:type => audiogram.mask_ac_rt_2k_type,  :level => audiogram.mask_ac_rt_2k} ,
               {:type => audiogram.mask_ac_rt_4k_type,  :level => audiogram.mask_ac_rt_4k} ,
               {:type => audiogram.mask_ac_rt_8k_type,  :level => audiogram.mask_ac_rt_8k} ]
    la_mask = [{:type => audiogram.mask_ac_lt_125_type, :level => audiogram.mask_ac_lt_125},
               {:type => audiogram.mask_ac_lt_250_type, :level => audiogram.mask_ac_lt_250},
               {:type => audiogram.mask_ac_lt_500_type, :level => audiogram.mask_ac_lt_500},
               {:type => audiogram.mask_ac_lt_1k_type,  :level => audiogram.mask_ac_lt_1k} ,
               {:type => audiogram.mask_ac_lt_2k_type,  :level => audiogram.mask_ac_lt_2k} ,
               {:type => audiogram.mask_ac_lt_4k_type,  :level => audiogram.mask_ac_lt_4k} ,
               {:type => audiogram.mask_ac_lt_8k_type,  :level => audiogram.mask_ac_lt_8k} ]
    rb_mask = [{:type => nil, :level => nil},
               {:type => audiogram.mask_bc_rt_250_type, :level => audiogram.mask_bc_rt_250},
               {:type => audiogram.mask_bc_rt_500_type, :level => audiogram.mask_bc_rt_500},
               {:type => audiogram.mask_bc_rt_1k_type,  :level => audiogram.mask_bc_rt_1k} ,
               {:type => audiogram.mask_bc_rt_2k_type,  :level => audiogram.mask_bc_rt_2k} ,
               {:type => audiogram.mask_bc_rt_4k_type,  :level => audiogram.mask_bc_rt_4k} ,
               {:type => audiogram.mask_bc_rt_8k_type,  :level => audiogram.mask_bc_rt_8k} ]
    lb_mask = [{:type => nil, :level => nil},
               {:type => audiogram.mask_bc_lt_250_type, :level => audiogram.mask_bc_lt_250},
               {:type => audiogram.mask_bc_lt_500_type, :level => audiogram.mask_bc_lt_500},
               {:type => audiogram.mask_bc_lt_1k_type,  :level => audiogram.mask_bc_lt_1k} ,
               {:type => audiogram.mask_bc_lt_2k_type,  :level => audiogram.mask_bc_lt_2k} ,
               {:type => audiogram.mask_bc_lt_4k_type,  :level => audiogram.mask_bc_lt_4k} ,
               {:type => audiogram.mask_bc_lt_8k_type,  :level => audiogram.mask_bc_lt_8k} ]
    return Audiodata.new("cooked", ra_data, la_data, rb_data, lb_data, \
                                   ra_mask, la_mask, rb_mask, lb_mask)
  end
end

