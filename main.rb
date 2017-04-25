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

  get '/patients_by_id/:hp_id' do # patients_by_id
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

  post '/patients_by_id/:hp_id/create_exam' do # patients_by_id_create_exam
    # create exam data directly from http request
    # データなどはmultipart/form-dataの形式で送信する
    # params は params[:datatype][:examdate][:equip_name][:comment][:data]
    # equip_name は検査機器の名称: 'AA-97' など
    # datatype は今のところ 'audiogram', 'impedance', 'images'
    hp_id = valid_id?(params[:hp_id]) || "invalid_id"
    if not @patient = Patient.find_by_hp_id(hp_id)
      @patient = Patient.new
      @patient.hp_id = hp_id
    end

    if @patient.save
      case params[:datatype]
      when "audiogram"
        @audiogram = @patient.audiograms.create
        @audiogram.examdate = Time.local *params[:examdate].split(/:|-/)
        @audiogram.audiometer = params[:equip_name]
        @audiogram.comment = parse_comment(params[:comment])
        @audiogram.manual_input = false
        if params[:data] && set_data(params[:data])
          build_graph
          if @audiogram.save
            204 # No Content # success
          else
            [400, 'the audiogram cannot be saved'] # 400 # Bad Request
          end
        else
            [400, 'data error'] # 400 # Bad Request
        end
      else
        [400,'data type not set'] # 400 # Bad Request
      end
    else
      [400, 'the patient cannnot be saved'] # 400 # Bad Request
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

  get '/patients/:patient_id/audiograms/:id/edit' do # audiograms#edit
    protected!
    @patient = Patient.find(params[:patient_id])
    @audiogram = @patient.audiograms.find(params[:id])
    erb :audiograms_edit
  end

  put '/patients/:patient_id/audiograms/:id' do # audiograms#update
    @patient = Patient.find(params[:patient_id])
    @audiogram = @patient.audiograms.find(params[:id])
    if @audiogram.update(select_params(params, [:examdate, :comment, :image_location,
      :ac_rt_125, :ac_rt_250, :ac_rt_500, :ac_rt_1k, :ac_rt_2k, :ac_rt_4k, :ac_rt_8k,
      :ac_lt_125, :ac_lt_250, :ac_lt_500, :ac_lt_1k, :ac_lt_2k, :ac_lt_4k, :ac_lt_8k,
      :bc_rt_250, :bc_rt_500, :bc_rt_1k, :bc_rt_2k, :bc_rt_4k, :bc_rt_8k,
      :bc_lt_250, :bc_lt_500, :bc_lt_1k, :bc_lt_2k, :bc_lt_4k, :bc_lt_8k,
      :ac_rt_125_scaleout, :ac_rt_250_scaleout, :ac_rt_500_scaleout, :ac_rt_1k_scaleout,
        :ac_rt_2k_scaleout, :ac_rt_4k_scaleout, :ac_rt_8k_scaleout,
      :ac_lt_125_scaleout, :ac_lt_250_scaleout, :ac_lt_500_scaleout, :ac_lt_1k_scaleout,
        :ac_lt_2k_scaleout, :ac_lt_4k_scaleout, :ac_lt_8k_scaleout,
      :bc_rt_250_scaleout, :bc_rt_500_scaleout, :bc_rt_1k_scaleout,
        :bc_rt_2k_scaleout, :bc_rt_4k_scaleout, :bc_rt_8k_scaleout,
      :bc_lt_250_scaleout, :bc_lt_500_scaleout, :bc_lt_1k_scaleout,
        :bc_lt_2k_scaleout, :bc_lt_4k_scaleout, :bc_lt_8k_scaleout,
      :mask_ac_rt_125, :mask_ac_rt_250, :mask_ac_rt_500, :mask_ac_rt_1k,
        :mask_ac_rt_2k, :mask_ac_rt_4k, :mask_ac_rt_8k,
      :mask_ac_lt_125, :mask_ac_lt_250, :mask_ac_lt_500, :mask_ac_lt_1k,
        :mask_ac_lt_2k, :mask_ac_lt_4k, :mask_ac_lt_8k,
      :mask_bc_rt_250, :mask_bc_rt_500, :mask_bc_rt_1k, :mask_bc_rt_2k, :mask_bc_rt_4k, :mask_bc_rt_8k,
      :mask_bc_lt_250, :mask_bc_lt_500, :mask_bc_lt_1k, :mask_bc_lt_2k, :mask_bc_lt_4k, :mask_bc_lt_8k,
      :mask_ac_rt_125_type, :mask_ac_rt_250_type, :mask_ac_rt_500_type, :mask_ac_rt_1k_type,
        :mask_ac_rt_2k_type, :mask_ac_rt_4k_type, :mask_ac_rt_8k_type,
      :mask_ac_lt_125_type, :mask_ac_lt_250_type, :mask_ac_lt_500_type, :mask_ac_lt_1k_type,
        :mask_ac_lt_2k_type, :mask_ac_lt_4k_type, :mask_ac_lt_8k_type,
      :mask_bc_rt_250_type, :mask_bc_rt_500_type, :mask_bc_rt_1k_type,
        :mask_bc_rt_2k_type, :mask_bc_rt_4k_type, :mask_bc_rt_8k_type,
      :mask_bc_lt_250_type, :mask_bc_lt_500_type, :mask_bc_lt_1k_type,
        :mask_bc_lt_2k_type, :mask_bc_lt_4k_type, :mask_bc_lt_8k_type,
      :manual_input, :audiometer, :hospital]))
      redirect to("/patients/#{@patient.id}/audiograms/#{@audiogram.id}")
    else
      erb :audiograms_edit
    end
  end

  delete '/patients/:patient_id/audiograms/:id' do # patients#destroy
    protected!
    @patient = Patient.find(params[:patient_id])
    @audiogram = @patient.audiograms.find(params[:id])
    @audiogram.destroy
    redirect to("/patients/#{@patient.id}/audiograms")
  end

#  get '/patients/:patient_id/audiograms/new' do # audiograms#new
#  end

#  post '/patients/:patient_id/audiograms' do # audiograms#create
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

  def set_data(data)
    begin
      d = Audiodata.new("raw", data)
      convert_to_audiogram(d, @audiogram)
    rescue
      return false
    else
      return true
    end
  end


  def convert_to_audiogram(audiodata, audiogram)
    d = audiodata.extract
    a = audiogram

    ra_data = d[:ra][:data]  # Array of floats
    a.ac_rt_125, a.ac_rt_250, a.ac_rt_500, a.ac_rt_1k, a.ac_rt_2k, a.ac_rt_4k, a.ac_rt_8k = \
      ra_data[0], ra_data[1], ra_data[2], ra_data[3], ra_data[4], ra_data[5], ra_data[6]
    la_data = d[:la][:data]
    a.ac_lt_125, a.ac_lt_250, a.ac_lt_500, a.ac_lt_1k, a.ac_lt_2k, a.ac_lt_4k, a.ac_lt_8k = \
      la_data[0], la_data[1], la_data[2], la_data[3], la_data[4], la_data[5], la_data[6]

    rb_data = d[:rb][:data]
    a.bc_rt_250, a.bc_rt_500, a.bc_rt_1k, a.bc_rt_2k, a.bc_rt_4k, a.bc_rt_8k = \
      rb_data[1], rb_data[2], rb_data[3], rb_data[4], rb_data[5], rb_data[6]
    lb_data = d[:lb][:data]
    a.bc_lt_250, a.bc_lt_500, a.bc_lt_1k, a.bc_lt_2k, a.bc_lt_4k, a.bc_lt_8k = \
      lb_data[1], lb_data[2], lb_data[3], lb_data[4], lb_data[5], lb_data[6]

    ra_so = d[:ra][:scaleout]  # Array of booleans
    a.ac_rt_125_scaleout, a.ac_rt_250_scaleout, a.ac_rt_500_scaleout, \
      a.ac_rt_1k_scaleout, a.ac_rt_2k_scaleout, a.ac_rt_4k_scaleout, a.ac_rt_8k_scaleout = \
      ra_so[0], ra_so[1], ra_so[2], ra_so[3], ra_so[4], ra_so[5], ra_so[6]
    la_so = d[:la][:scaleout]
    a.ac_lt_125_scaleout, a.ac_lt_250_scaleout, a.ac_lt_500_scaleout, \
      a.ac_lt_1k_scaleout, a.ac_lt_2k_scaleout, a.ac_lt_4k_scaleout, a.ac_lt_8k_scaleout = \
      la_so[0], la_so[1], la_so[2], la_so[3], la_so[4], la_so[5], la_so[6]

    rb_so = d[:rb][:scaleout]
    a.bc_rt_250_scaleout, a.bc_rt_500_scaleout, a.bc_rt_1k_scaleout, \
      a.bc_rt_2k_scaleout, a.bc_rt_4k_scaleout, a.bc_rt_8k_scaleout = \
      rb_so[1], rb_so[2], rb_so[3], rb_so[4], rb_so[5], rb_so[6]
    lb_so = d[:lb][:scaleout]
    a.bc_lt_250_scaleout, a.bc_lt_500_scaleout, a.bc_lt_1k_scaleout, \
      a.bc_lt_2k_scaleout, a.bc_lt_4k_scaleout, a.bc_lt_8k_scaleout = \
      lb_so[1], lb_so[2], lb_so[3], lb_so[4], lb_so[5], lb_so[6]

    #  Air-Rt, data type of :mask is Array, data-order: mask_type, mask_level
    a.mask_ac_rt_125 = d[:ra][:mask][0][1].to_f rescue nil    # Air-rt
    a.mask_ac_rt_125_type = d[:ra][:mask][0][0] rescue nil
    a.mask_ac_rt_250 = d[:ra][:mask][1][1].to_f rescue nil
    a.mask_ac_rt_250_type = d[:ra][:mask][1][0] rescue nil
    a.mask_ac_rt_500 = d[:ra][:mask][2][1].to_f rescue nil
    a.mask_ac_rt_500_type = d[:ra][:mask][2][0] rescue nil
    a.mask_ac_rt_1k = d[:ra][:mask][3][1].to_f rescue nil
    a.mask_ac_rt_1k_type = d[:ra][:mask][3][0] rescue nil
    a.mask_ac_rt_2k = d[:ra][:mask][4][1].to_f rescue nil
    a.mask_ac_rt_2k_type = d[:ra][:mask][4][0] rescue nil
    a.mask_ac_rt_4k = d[:ra][:mask][5][1].to_f rescue nil
    a.mask_ac_rt_4k_type = d[:ra][:mask][5][0] rescue nil
    a.mask_ac_rt_8k = d[:ra][:mask][6][1].to_f rescue nil
    a.mask_ac_rt_8k_type = d[:ra][:mask][6][0] rescue nil

    a.mask_ac_lt_125 = d[:la][:mask][0][1].to_f rescue nil    #  Air-Lt
    a.mask_ac_lt_125_type = d[:la][:mask][0][0] rescue nil
    a.mask_ac_lt_250 = d[:la][:mask][1][1].to_f rescue nil
    a.mask_ac_lt_250_type = d[:la][:mask][1][0] rescue nil
    a.mask_ac_lt_500 = d[:la][:mask][2][1].to_f rescue nil
    a.mask_ac_lt_500_type = d[:la][:mask][2][0] rescue nil
    a.mask_ac_lt_1k = d[:la][:mask][3][1].to_f rescue nil
    a.mask_ac_lt_1k_type = d[:la][:mask][3][0] rescue nil
    a.mask_ac_lt_2k = d[:la][:mask][4][1].to_f rescue nil
    a.mask_ac_lt_2k_type = d[:la][:mask][4][0] rescue nil
    a.mask_ac_lt_4k = d[:la][:mask][5][1].to_f rescue nil
    a.mask_ac_lt_4k_type = d[:la][:mask][5][0] rescue nil
    a.mask_ac_lt_8k = d[:la][:mask][6][1].to_f rescue nil
    a.mask_ac_lt_8k_type = d[:la][:mask][6][0] rescue nil

    a.mask_bc_rt_250 = d[:rb][:mask][1][1].to_f rescue nil    #  Bone-Rt
    a.mask_bc_rt_250_type = d[:rb][:mask][1][0] rescue nil
    a.mask_bc_rt_500 = d[:rb][:mask][2][1].to_f rescue nil
    a.mask_bc_rt_500_type = d[:rb][:mask][2][0] rescue nil
    a.mask_bc_rt_1k = d[:rb][:mask][3][1].to_f rescue nil
    a.mask_bc_rt_1k_type = d[:rb][:mask][3][0] rescue nil
    a.mask_bc_rt_2k = d[:rb][:mask][4][1].to_f rescue nil
    a.mask_bc_rt_2k_type = d[:rb][:mask][4][0] rescue nil
    a.mask_bc_rt_4k = d[:rb][:mask][5][1].to_f rescue nil
    a.mask_bc_rt_4k_type = d[:rb][:mask][5][0] rescue nil
    a.mask_bc_rt_8k = d[:rb][:mask][6][1].to_f rescue nil
    a.mask_bc_rt_8k_type = d[:rb][:mask][6][0] rescue nil

    a.mask_bc_lt_250 = d[:lb][:mask][1][1].to_f rescue nil    #  Bone-Lt
    a.mask_bc_lt_250_type = d[:lb][:mask][1][0] rescue nil
    a.mask_bc_lt_500 = d[:lb][:mask][2][1].to_f rescue nil
    a.mask_bc_lt_500_type = d[:lb][:mask][2][0] rescue nil
    a.mask_bc_lt_1k = d[:lb][:mask][3][1].to_f rescue nil
    a.mask_bc_lt_1k_type = d[:lb][:mask][3][0] rescue nil
    a.mask_bc_lt_2k = d[:lb][:mask][4][1].to_f rescue nil
    a.mask_bc_lt_2k_type = d[:lb][:mask][4][0] rescue nil
    a.mask_bc_lt_4k = d[:lb][:mask][5][1].to_f rescue nil
    a.mask_bc_lt_4k_type = d[:lb][:mask][5][0] rescue nil
    a.mask_bc_lt_8k = d[:lb][:mask][6][1].to_f rescue nil
    a.mask_bc_lt_8k_type = d[:lb][:mask][6][0] rescue nil

    return a
  end

  def parse_comment(comment)
    ss = StringScanner.new(comment)
    result = String.new
    until ss.eos? do
      case
      when ss.scan(/RETRY_/)
        result += "再検査(RETRY)/"
      when ss.scan(/MASK_/)
        result += "マスキング変更(MASK)/"
      when ss.scan(/PATCH_/)
        result += "パッチテスト(PATCH)/"
      when ss.scan(/MED_/)
        result += "薬剤投与後(MED)/"
      when ss.scan(/OTHER:(.*)_/)
        result += "\n"
        result += "・#{ss[1]}"
      else
        break
      end
    end
    return result
  end

end

