require File.expand_path '../test_helper.rb', __FILE__

require 'factory_bot'
require './main'
require './lib/id_validation'

FactoryBot.find_definitions

describe 'AudiogramsController' do
  before do
    Patient.delete_all
    @patient = FactoryBot.create(:patient)
    @right_user = "audioadmin"
    @right_pw = "audioadmin"
    @wrong_pw = "wrong_password"
  end

  # return the minimal set of attributes required to create a valid Audiogram
  def valid_attributes
    {examdate: Time.now, image_location: "graphs_some_directory", audiometer: 'audiometer'}
  end

  def valid_session
    {}
  end

  describe "GET audiograms#index (/patients/:patient_id/audiograms)" do
    before do
      audiogram = Audiogram.create!(
        examdate: Time.now, comment: "Comment",
        image_location: "graphs_some_directory",
        ac_rt_500: 10, ac_rt_1k: 20, ac_rt_2k: 30,
        ac_lt_500: 15, ac_lt_1k: 25, ac_lt_2k: 35,
        audiometer: "Audiometer", hospital: "Hospital"
      )
      @patient.audiograms = []
      @patient.audiograms << audiogram
      get "/patients/#{@patient.id}/audiograms"
      @response = last_response
    end

    it "全ての audiogram が表示されること(all audiograms must be shown" do
      _(@response.ok?).must_equal true
      _(@response.body).must_include "<!-- /patients/#{@patient.id}/audiograms -->"
      @patient.audiograms.each do |audiogram|
        ex_date = audiogram.examdate.strftime("%Y/%m/%d")
        ex_time = audiogram.examdate.strftime("%X")
        _(@response.body).must_include ex_date
        _(@response.body).must_include ex_time
      end
    end

    it 'patients#show への link があること(has a link to patients#show)' do
      _(@response.body).must_include "patients/#{@patient.id}"
    end

    it 'audiogram の数に応じて単数複数が表示されること(can use pluralization)' do
      _(@response.body).must_match(/1 audiogram[^s]/)
      audiogram2 = Audiogram.create!(
        examdate: Time.now, comment: "Comment",
        image_location: "graphs_some_directory",
        ac_rt_500: 10, ac_rt_1k: 20, ac_rt_2k: 30,
        ac_lt_500: 15, ac_lt_1k: 25, ac_lt_2k: 35,
        audiometer: "Audiometer", hospital: "Hospital"
      )
      @patient.audiograms << audiogram2
      get "/patients/#{@patient.id}/audiograms"
      _(last_response.body).must_include "2 audiograms"
    end

    it 'audiograms#show への link があること(has a link to audiograms#show)' do
      @patient.audiograms.each do |audiogram|
        _(@response.body).must_include "patients/#{@patient.id}/audiograms/#{audiogram.id}"
      end
    end

    it 'audiograms#destroy への link があること(has a link to audigrams#destroy)' do
      @patient.audiograms.each do |audiogram|
        _(@response.body).must_include \
          "<form action=\"/patients/#{@patient.id}/audiograms/#{audiogram.id}\" method=\"POST\">"
        _(@response.body).must_include "<input type=\"hidden\" name=\"_method\" value=\"DELETE\">"
      end
    end

    it 'audiograms#new への link があること(has a link to audiograms#new)' do
      _(@response.body).must_include "patients/#{@patient.id}/audiograms/new"
    end
  end

  describe "GET audiograms#show (/patients/:patient_id/audiograms/:id)" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @audiogram.ac_rt_500, @audiogram.ac_rt_1k, @audiogram.ac_rt_2k =  0, 10, 20
      @audiogram.ac_lt_500, @audiogram.ac_lt_1k, @audiogram.ac_lt_2k = 40, 60, 70
      @audiogram.examdate = Time.now
      exam_year = @audiogram.examdate.strftime("%Y")
      base_dir = "#{ENV['RACK_ENV']}/graphs/#{exam_year}"
      @audiogram.image_location = "#{base_dir}/#{@audiogram.examdate.strftime("%Y%m%d-%H%M%S")}.png"
      app_root = File.dirname(app.app_file)
      image_root = "assets/images"
      image_dir = "#{app_root}/#{image_root}/#{base_dir}" 
      @image_file = "#{app_root}/#{image_root}/#{@audiogram.image_location}"
      FileUtils.makedirs(image_dir) if not File.exist?(image_dir)
      File::delete(@image_file) if File.exist?(@image_file)
      File::open(@image_file, "w") do |f|
        f.write (@test_str = "test_string")
      end
      @patient.audiograms << @audiogram
      get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
      @response = last_response
    end

    it "指定された audiogram が表示されること(shows the audiogram)" do
      _(@response.ok?).must_equal true
      _(@response.body).must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id} -->"
      _(@response.body).must_include @audiogram.examdate.to_s
    end

    it "4分法平均値が表示されること(shows the mean value of audiogram" do
      _(@response.body).must_include '10.0'
      _(@response.body).must_include '57.5'
    end

    it 'audiogram のコメントが編集できること(can edit a comment)' do
      _(@response.body).must_include "patients/#{@patient.id}/audiograms/#{@audiogram.id}"
      _(@response.body).must_include '<input type="hidden" name="_method" value="PUT">'
      _(@response.body).must_include '<input type="text" name="comment"'
      _(@response.body).must_include '<input type="submit"'
    end

    it '印刷ボタンが表示されること(can show a [print] button' do
      _(@response.body).must_match(/<input type.+button.+onclick.+print()/)
    end

    it 'audiogram 一覧 (audiograms#index) への link があること(has a link to audiograms#index)' do
      _(@response.body).must_include "patients/#{@patient.id}/audiograms"
    end

    it "聴検の画像が保存されている場合、画像が更新されないこと(doesn't touch the graph when the graph was already saved)" do
      content = String.new
      File::open(@image_file) do |f|
        content = f.read
      end
      _(content).must_equal @test_str
    end

    it "聴検の画像が保存されていない場合、画像を作成すること(make a graph when the graph hasn't be saved)" do
      File::delete(@image_file) if File.exist?(@image_file)
      get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
      _(File.exist?(@image_file)).must_equal true
    end
  end

  describe "GET audiograms#edit (/patients/:patient_id/audiograms/:id/edit)" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @patient.audiograms << @audiogram
    end

    describe "basic認証をpassする場合(when basic-auth was passed)" do
      before do
        basic_authorize @right_user, @right_pw
        get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit"
        @response = last_response
      end

      it "指定された patient, audiogram の編集画面が得られること(can get a edit page of the audiogram of the patient)" do
        _(@response.ok?).must_equal true
        _(@response.body).must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit -->"
      end

      it "post /patients へ遷移する form を持つこと(has a form to migrate to 'post /patients'" do
        _(@response.body).must_match \
          Regexp.new("form action=\"/patients/#{@patient.id}/audiograms/#{@audiogram.id}\" method=\"POST\"")
        _(@response.body).must_match Regexp.new("name=\"_method\" value=\"PUT\"")
      end
    end

    describe "basic認証をpassしない場合(when basic-auth was not passed" do
      it "401 status code [Unauthorized] が帰ってくること(returns 401[Unauthorized])" do
        basic_authorize @right_user, @wrong_pw
        get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit"
        _(last_response.status).must_equal 401
      end
    end

    describe "basic認証に対して username:password を提示しない場合(when not given username:password to basic-auth)" do
      it "401 status code [Unauthorized] が帰ってくること(returns 401[Unautorized])" do
        get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit"
        _(last_response.status).must_equal 401
      end
    end
  end

  describe "PUT audiograms#update (/patients/:patient_id/audiograms/:id)" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @patient.audiograms << @audiogram
    end

    describe "valid params を入力した場合(when params were valid)" do
      it "指定された audiogram が update されること(updates the audiogram)" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: 'update',\
                                                                            examdate: Time.now}
        audiogram_reloaded = Audiogram.find(@audiogram.id)
        _(audiogram_reloaded.audiometer).wont_equal @audiogram.audiometer
      end

      it "redirect されること(redirects the page)" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: @audiogram.audiometer,\
                                                                            examdate: @audiogram.examdate}
        _(last_response.redirect?).must_equal true
      end

      it "redirect された先が、指定された patient/audiogram の view であること(redirects to the view of the audiogram of the patient)" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: @audiogram.audiometer,\
                                                                            examdate: @audiogram.examdate}
        follow_redirect!
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id} -->"
      end
    end

    describe "valid でない params を入力した場合(when params were not valid)" do
      it "指定された patient が update されないこと(doesn't update the patient)" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: nil}
        audiogram_reloaded = Audiogram.find(@audiogram.id)
        _(audiogram_reloaded.audiometer).must_equal @audiogram.audiometer
      end

      it "/patients/:patient_id/audiograms/:id/edit の view を表示すること(shows the view of /patients/:patient_id/audiograms/:id/edit" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: nil}
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit -->"
      end
    end
  end

  describe "DELETE audiograms#destroy (/patients/:patient_id/audiograms/:id)" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @patient.audiograms << @audiogram
    end

    describe "basic認証に対して username:password を提示しない場合(when username:password were not given to basic-auth)" do
      it "指定された audiogram が削除されないこと(doen't delete the audiogram)" do
        audiogram_num = Audiogram.all.length
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(Audiogram.all.length).must_equal audiogram_num
      end

      it "redirect されないこと(doesn't redirect)" do
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(last_response.redirect?).wont_equal true
      end

      it "401 status code [Unauthorized] が帰ってくること(returns 401[Unauthorized]" do
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(last_response.status).must_equal 401
      end
    end

    describe "basic認証をpassしない場合(when basic-auth didn't pass)" do
      before do
        basic_authorize @right_user, @wrong_pw
      end

      it "指定された audiogram が削除されないこと(doesn't delete the audiogram)" do
        audiogram_num = Audiogram.all.length
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(Audiogram.all.length).must_equal audiogram_num
      end

      it "redirect されないこと(doesn't redirect)" do
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(last_response.redirect?).wont_equal true
      end

      it "401 status code [Unauthorized] が帰ってくること(returns 401[Unauthorized]" do
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(last_response.status).must_equal 401
      end
    end

    describe "basic認証をpassする場合(when basic-auth passed" do
      before do
        basic_authorize @right_user, @right_pw
      end

      it "指定された audiogram を削除すること(delete the audiogram)" do
        audiogram_num = Audiogram.all.length
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(Audiogram.all.length).must_equal (audiogram_num - 1)
      end

      it "redirect されること(redirects)" do
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        _(last_response.redirect?).must_equal true
      end

      it "redirect 先が、全ての audiogams のリストであること(redirects to the list of all audiograms)" do
        delete "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
        follow_redirect!
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/#{@patient.id}/audiograms -->"
      end
    end
  end

  describe "PUT audiograms#edit_comment (/patients/:patient_id/audiograms/:id/edit_comment)" do
    before do
      @old_comment = "Old comment"
      @new_comment = "New comment"
      audiogram = Audiogram.create! valid_attributes
      audiogram.comment = @old_comment
      audiogram.save
      @patient.audiograms = []
      @patient.audiograms << audiogram
      @audiogram = @patient.audiograms.first
    end

    it "commentを更新できること(update the comment)" do
      _(@patient.audiograms.length).must_equal 1
      _(@audiogram.comment).must_equal @old_comment
      put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit_comment",\
        params={comment: @new_comment}
      _(@audiogram.reload.comment).must_equal @new_comment
    end

    it "redirectされること(redirects)" do
      put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit_comment",\
        params={comment: @new_comment}
      _(last_response.redirect?).must_equal true
    end

    it "redirect された先が、指定された patient/audiogram の view であること(redirects to the view of the audiogram of the patient)" do
      put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit_comment",\
        params={comment: @new_comment}
      follow_redirect!
      _(last_response.ok?).must_equal true
      _(last_response.body).must_include \
        "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id} -->"
    end
  end

  describe "POST audiograms#direct_create (/audiograms/direct_create)" do
    # params は params[:hp_id][:datatype][:examdate][:audiometer][:comment][:data]
    # datatype は今のところ audiogram, impedance, images

    before do
      @valid_hp_id = 19
      @invalid_hp_id = 18
      @examdate = Time.now.strftime("%Y:%m:%d-%H:%M:%S")
      @audiometer = "audiometer"
      @datatype = "audiogram"
#      @comment = "comment" + rand.to_s
      @random_number = rand.to_s
      @comment = "OTHER:" + @random_number + "_"
      @raw_audiosample = "7@/          /  080604  //   0   30 ,  10   35 ,  20   40 ,          ,  30   45 ,          ,  40   50 ,          ,  50   55 ,          ,  60   60 ,          , -10   55 ,  -5   55 ,          ,   0   55 ,          ,   5   55 ,          ,  10   55 ,          ,  15   55 ,  4>  4<,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,/P"
      #  125 250 500  1k  2k  4k  8k
      #R   0  10  20  30  40  50  60
      #L  30  35  40  45  50  55  60
    end

    describe "audiogramの描画に関して" do
      it "必要なfontがインストールされていること" do
        if `uname`.match(/FreeBSD/)
          _(`pkg info |grep IPA`).must_match(/IPAex/)
        end
      end
    end

    describe "datatypeがない場合" do
      it "HTTP status code 400を返すこと" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
	                      :equip_name => @audiometer, :comment => @comment, :data => @raw_audiosample}
        _(last_response.status).must_equal 400
      end
    end

    describe "datatypeがaudiogramの場合" do
      it "正しいパラメータの場合、Audiogramのアイテム数が1増えること" do
        audiogram_num = Audiogram.all.length
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment, :data => @raw_audiosample}
        _(Audiogram.all.length).must_equal (audiogram_num + 1)
      end

      it "正しいパラメータの場合、maskingのデータが取得されること" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment, :data => @raw_audiosample}
        _(Audiogram.last.comment).must_include "・"+@random_number
        _(Audiogram.last.mask_ac_rt_125).wont_be_nil
      end

      it "正しいパラメータの場合、HTTP status code 204を返すこと" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment, :data => @raw_audiosample}
        _(last_response.status).must_equal 204
      end

      it "正しいパラメータの場合、所定の位置にグラフとサムネイルが作られること" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment, :data => @raw_audiosample}
        a = Audiogram.last
        img_loc = "assets/#{a.image_location}"
        thumb_loc = img_loc.sub("graphs", "thumbnails")
        _(File.exist?(img_loc)).must_equal true
        _(File.exist?(thumb_loc)).must_equal true
      end

      it "audiometerの入力がない場合、HTTP status code 400を返すこと" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :datatype => @datatype, \
                      :comment => @comment, :data => @raw_audiosample}
        _(last_response.status).must_equal 400
      end

      it "dataがない場合、HTTP status code 400を返すこと" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment}
        _(last_response.status).must_equal 400
      end

      it "data形式が不正の場合、HTTP status code 400を返すこと" do
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment, :data => "no valid data"}
        _(last_response.status).must_equal 400
      end

      it "hp_idが存在しないものの場合、新たにPatientを作成し、Audiogramのアイテム数が1増えること" do
        if patient_to_delete = Patient.find_by_hp_id(@valid_hp_id)
          patient_to_delete.destroy
        end
        patient_num = Patient.all.length
        audiogram_num = Audiogram.all.length
        post "audiograms/direct_create", {:hp_id => @valid_hp_id, :examdate => @examdate, \
                      :equip_name => @audiometer, :datatype => @datatype, \
                      :comment => @comment, :data => @raw_audiosample}
        _(Patient.all.length).must_equal (patient_num + 1)
        _(Audiogram.all.length).must_equal (audiogram_num + 1)
      end

      if Id_validation.state
        it "(以前のsystremでは)不正なhp_idの場合、HTTP status code 400を返すこと" do
          post "audiograms/direct_create", {:hp_id => @invalid_hp_id, :examdate => @examdate, \
                        :equip_name => @audiometer, :datatype => @datatype, \
                        :comment => @comment, :data => @raw_audiosample}
          _(last_response.status).must_equal 400
        end
      else
        it "(以前のsystremでは)不正なhp_idの場合も、HTTP status code 204を返すこと" do
          post "audiograms/direct_create", {:hp_id => @invalid_hp_id, :examdate => @examdate, \
                        :equip_name => @audiometer, :datatype => @datatype, \
                        :comment => @comment, :data => @raw_audiosample}
          _(last_response.status).must_equal 204
        end
      end

      describe "comment内容による @patient.audiogram.commentの変化について" do
        before do
          @patient.hp_id = valid_id?(@patient.hp_id)
          @patient.save
        end

        def direct_create_with_comment(com)
          post "audiograms/direct_create", {:hp_id => @patient.hp_id, :examdate => @examdate, \
                        :equip_name => @audiometer, :datatype => @datatype, \
                        :comment => com, :data => @raw_audiosample}
          @patient.reload
        end

        it "1つのcommentがある場合、それに応じたコメントが記録されること" do
          direct_create_with_comment("RETRY_")
          _(@patient.audiograms.last.comment).must_match(/再検査\(RETRY\)/)
          direct_create_with_comment("MASK_")
          _(@patient.audiograms.last.comment).must_match(/マスキング変更\(MASK\)/)
          direct_create_with_comment("PATCH_")
          _(@patient.audiograms.last.comment).must_match(/パッチテスト\(PATCH\)/)
          direct_create_with_comment("MED_")
          _(@patient.audiograms.last.comment).must_match(/薬剤投与後\(MED\)/)
          direct_create_with_comment("OTHER:幾つかのコメント_")
          _(@patient.audiograms.last.comment).must_match(/^・幾つかのコメント/)
        end

        it "2つのcommentがある場合、それに応じたコメントが記録されること" do
          direct_create_with_comment("RETRY_MASK_")
          _(@patient.audiograms.last.comment).must_match(/再検査\(RETRY\)/)
          _(@patient.audiograms.last.comment).must_match(/マスキング変更\(MASK\)/)
          direct_create_with_comment("MED_OTHER:幾つかのコメント_")
          _(@patient.audiograms.last.comment).must_match(/薬剤投与後\(MED\)/)
          _(@patient.audiograms.last.comment).must_match(/^・幾つかのコメント/)
        end
      end

      it "examdateが設定されていない場合..." do
        skip "どうしたものかまだ思案中"
      end
    end

  end

  describe "GET audiograms#all_rebuild (/audiograms/all_rebuild)" do
    # params は params[:hp_id][:datatype][:examdate][:audiometer][:comment][:data]
    # datatype は今のところ audiogram, impedance, images

    before do
      Patient.destroy_all
      Audiogram.destroy_all
      @valid_hp_id1 = 19
      @valid_hp_id2 = 27
      @examdate1 = Time.now.strftime("%Y:%m:%d-%H:%M:%S")
      @examdate2 = (Time.now + 5 * 24 * 3600).strftime("%Y:%m:%d-%H:%M:%S")
      @audiometer = "audiometer"
      @datatype = "audiogram"
      @random_number = rand.to_s
      @comment = "OTHER:" + @random_number + "_"
      @raw_audiosample1 = "7@/          /  080604  //   0   30 ,  10   35 ,  20   40 ,          ,  30   45 ,          ,  40   50 ,          ,  50   55 ,          ,  60   60 ,          , -10   55 ,  -5   55 ,          ,   0   55 ,          ,   5   55 ,          ,  10   55 ,          ,  15   55 ,  4>  4<,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,/P"
      #  125 250 500  1k  2k  4k  8k
      #R   0  10  20  30  40  50  60
      #L  30  35  40  45  50  55  60
      @raw_audiosample2 = "7@/          /  080604  //   0   30 ,  10   35 ,  20   40 ,          ,  30   45 ,          ,  20   50 ,          ,  10   55 ,          ,  10   60 ,          , -10   55 ,  -5   55 ,          ,   0   55 ,          ,   5   55 ,          ,  10   55 ,          ,  15   55 ,  4>  4<,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,/U"
      #  125 250 500  1k  2k  4k  8k
      #R   0  10  20  30  20  10  10
      #L  30  35  40  45  50  55  60
      post "audiograms/direct_create", {:hp_id => @valid_hp_id1, :examdate => @examdate1, \
                    :equip_name => @audiometer, :datatype => @datatype, \
                    :comment => @comment, :data => @raw_audiosample1}
      post "audiograms/direct_create", {:hp_id => @valid_hp_id2, :examdate => @examdate2, \
                    :equip_name => @audiometer, :datatype => @datatype, \
                    :comment => @comment, :data => @raw_audiosample2}
    end

    it "元々存在する audiogram のグラフを消しても all_rebuild で同じものが再作成できること" do
      _(Audiogram.all.length).must_equal 2
      @md5_1 = Digest::MD5.file("./assets/#{Audiogram.first.image_location}")
      @md5_2 = Digest::MD5.file("./assets/#{Audiogram.last.image_location}")
      File.delete  "./assets/#{Audiogram.first.image_location}"
      File.delete  "./assets/#{Audiogram.last.image_location}"
      get "audiograms/all_rebuild"
      _(Audiogram.all.length).must_equal 2
      _(Digest::MD5.file("./assets/#{Audiogram.first.image_location}")).must_equal @md5_1
      _(Digest::MD5.file("./assets/#{Audiogram.last.image_location}")).must_equal @md5_2
    end

  end
end
