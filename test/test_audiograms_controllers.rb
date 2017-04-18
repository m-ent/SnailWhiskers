require File.expand_path '../test_helper.rb', __FILE__

require 'factory_girl'
require './main'
require './lib/id_validation'

FactoryGirl.find_definitions

describe 'AudiogramsController' do
  before do
    @patient = FactoryGirl.create(:patient)
    @right_user = "audioadmin"
    @right_pw = "audioadmin"
    @wrong_pw = "wrong_password"
  end

  # return the minimal set of attributes required to create a valid Audiogram
  def valid_attributes
    {examdate: Time.now, audiometer: 'audiometer'}
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

    it "全ての audiogram が表示されること" do
      @response.ok?.must_equal true
      @response.body.must_include "<!-- /patients/#{@patient.id}/audiograms -->"
      @patient.audiograms.each do |audiogram|
        ex_date = audiogram.examdate.strftime("%Y/%m/%d")
        ex_time = audiogram.examdate.strftime("%X")
        @response.body.must_include ex_date
        @response.body.must_include ex_time
      end
    end

    it 'patients#show への link があること' do
      @response.body.must_include "patients/#{@patient.id}"
    end

    it 'audiogram の数に応じて単数複数が表示されること' do
      @response.body.must_match /1 audiogram[^s]/
      audiogram2 = Audiogram.create!(
        examdate: Time.now, comment: "Comment",
	image_location: "graphs_some_directory",
        ac_rt_500: 10, ac_rt_1k: 20, ac_rt_2k: 30,
        ac_lt_500: 15, ac_lt_1k: 25, ac_lt_2k: 35,
        audiometer: "Audiometer", hospital: "Hospital"
      )
      @patient.audiograms << audiogram2
      get "/patients/#{@patient.id}/audiograms"
      last_response.body.must_include "2 audiograms"
    end

    it 'audiograms#show への link があること' do
      @patient.audiograms.each do |audiogram|
        @response.body.must_include "patients/#{@patient.id}/audiograms/#{audiogram.id}"
      end
    end

    it 'audiograms#destroy への link があること' do
      @patient.audiograms.each do |audiogram|
        @response.body.must_include \
          "<form action=\"/patients/#{@patient.id}/audiograms/#{audiogram.id}\" method=\"POST\">"
        @response.body.must_include "<input type=\"hidden\" name=\"_method\" value=\"DELETE\">"
      end
    end

    it 'audiograms#new への link があること' do
      @response.body.must_include "patients/#{@patient.id}/audiograms/new"
    end
  end

  describe "GET audiogram#show (/patients/:patient_id/audiograms/:id)" do
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
      FileUtils.makedirs(image_dir) if not File.exists?(image_dir)
      File::delete(@image_file) if File.exist?(@image_file)
      File::open(@image_file, "w") do |f|
        f.write (@test_str = "test_string")
      end
      @patient.audiograms << @audiogram
      get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
      @response = last_response
    end

    it "指定された audiogram が表示されること" do
      @response.ok?.must_equal true
      @response.body.must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id} -->"
      @response.body.must_include @audiogram.examdate.to_s
    end

    it "4分法平均値が表示されること" do
      @response.body.must_include '10.0'
      @response.body.must_include '57.5'
    end

    it 'audiogram のコメントが編集できること' do
      @response.body.must_include "patients/#{@patient.id}/audiograms/#{@audiogram.id}"
      @response.body.must_include '<input type="hidden" name="_method" value="PUT">'
      @response.body.must_include '<input type="text" name="comment"'
      @response.body.must_include '<input type="submit"'
    end

    it '印刷ボタンが表示されること' do
      @response.body.must_match /<input type.+button.+onclick.+print()/
    end

    it 'audiogram 一覧 (audiograms#index) への link があること' do
      @response.body.must_include "patients/#{@patient.id}/audiograms"
    end

    it "聴検の画像が保存されている場合、画像が更新されないこと" do
      content = String.new
      File::open(@image_file) do |f|
        content = f.read
      end
      content.must_equal @test_str
    end

    it "聴検の画像が保存されていない場合、画像を作成すること" do
      File::delete(@image_file) if File.exist?(@image_file)
      get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}"
      File.exist?(@image_file).must_equal true
    end
  end

  describe "GET audiogram#edit (/patients/:patient_id/audiograms/:id/edit)" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @patient.audiograms << @audiogram
    end

    describe "basic認証をpassする場合" do
      before do
        basic_authorize @right_user, @right_pw
        get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit"
        @response = last_response
      end

      it "指定された patient, audiogram の編集画面が得られること" do
        @response.ok?.must_equal true
        @response.body.must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit -->"
      end

      it "post /patients へ遷移する form を持つこと" do
        @response.body.must_match \
          Regexp.new("form action=\"/patients/#{@patient.id}/audiograms/#{@audiogram.id}\" method=\"POST\"")
        @response.body.must_match Regexp.new("name=\"_method\" value=\"PUT\"")
      end
    end

    describe "basic認証をpassしない場合" do
      it "401 status code (Unauthorized) が帰ってくること" do
        basic_authorize @right_user, @wrong_pw
        get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit"
        last_response.status.must_equal 401
      end
    end

    describe "basic認証に対して username:password を提示しない場合" do
      it "401 status code (Unauthorized) が帰ってくること" do
        get "/patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit"
        last_response.status.must_equal 401
      end
    end
  end

=begin
#----------------------------------------------
  describe "GET new" do
    it "assigns a new audiogram as @audiogram" do
      get :new, {:patient_id => @patient.to_param}, valid_session
      expect(assigns(:audiogram)).to be_a_new(Audiogram)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Audiogram" do
        expect {
          post :create, {:patient_id => @patient.to_param, :audiogram => valid_attributes}, valid_session
        }.to change(Audiogram, :count).by(1)
      end

      it "assigns a newly created audiogram as @audiogram" do
        post :create, {:patient_id => @patient.to_param, :audiogram => valid_attributes}, valid_session
        expect(assigns(:audiogram)).to be_a(Audiogram)
        expect(assigns(:audiogram)).to be_persisted
      end

      it "redirects to the created audiogram" do
        post :create, {:patient_id => @patient.to_param, :audiogram => valid_attributes}, valid_session
        expect(response).to redirect_to([@patient, Audiogram.last])
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved audiogram as @audiogram" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Audiogram).to receive(:save).and_return(false)
        post :create, {:patient_id => @patient.to_param, :audiogram => {}}, valid_session
        expect(assigns(:audiogram)).to be_a_new(Audiogram)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Audiogram).to receive(:save).and_return(false)
        post :create, {:patient_id => @patient.to_param, :audiogram => {}}, valid_session
        expect(response).to render_template("new")
      end
    end
  end
=end

  describe "PUT audiogram#update (/patients/:patient_id/audiograms/:id)" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @patient.audiograms << @audiogram
    end

    describe "valid params を入力した場合" do
      it "指定された audiogram が update されること" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: 'update', examdate: Time.now}
        audiogram_reloaded = Audiogram.find(@audiogram.id)
        audiogram_reloaded.audiometer.wont_equal @audiogram.audiometer
      end

      it "redirect されること" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: @audiogram.audiometer,\
                                                                            examdate: @audiogram.examdate}
        last_response.redirect?.must_equal true
      end

      it "redirect された先が、指定された patient/audiogram の view であること" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: @audiogram.audiometer,\
                                                                            examdate: @audiogram.examdate}
        follow_redirect!
        last_response.ok?.must_equal true
        last_response.body.must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id} -->"
      end
    end

    describe "valid でない params を入力した場合" do
      it "指定された patient が update されないこと" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: nil}
        audiogram_reloaded = Audiogram.find(@audiogram.id)
        audiogram_reloaded.audiometer.must_equal @audiogram.audiometer
      end

      it "/patients/:patient_id/audiograms/:id/edit の view を表示すること" do
        put "/patients/#{@patient.id}/audiograms/#{@audiogram.id}", params={audiometer: nil}
        last_response.ok?.must_equal true
        last_response.body.must_include "<!-- /patients/#{@patient.id}/audiograms/#{@audiogram.id}/edit -->"
      end
    end
  end

=begin
  describe "DELETE destroy" do
    before do
      @audiogram = Audiogram.create! valid_attributes
      @patient.audiograms << @audiogram
    end

    context "basic認証に対して username:passwordなしで操作した場合" do
      it "does not destroy the requested audiogram" do
        expect {
          delete :destroy, {:patient_id => @patient.to_param, :id => @audiogram.to_param},\
            valid_session
        }.to change(Audiogram, :count).by(0)
      end

      it "does not redirect to the audiograms list" do
        delete :destroy, {:patient_id => @patient.to_param, :id => @audiogram.to_param},\
          valid_session
        expect(response).not_to redirect_to(patient_audiograms_url)
      end
    end

    context "basic認証をpassしない場合" do
      before do
        request.env['HTTP_AUTHORIZATION'] = @wrong_auth
      end

      it "does not destroy the requested audiogram" do
        expect {
          delete :destroy, {:patient_id => @patient.to_param, :id => @audiogram.to_param},\
            valid_session
        }.to change(Audiogram, :count).by(0)
      end

      it "does not redirect to the audiograms list" do
        delete :destroy, {:patient_id => @patient.to_param, :id => @audiogram.to_param},\
          valid_session
        expect(response).not_to redirect_to(patient_audiograms_url)
      end
    end

    context "basic認証をpassする場合" do
      before do
        request.env['HTTP_AUTHORIZATION'] = @right_auth
      end

      it "destroys the requested audiogram" do
        expect {
          delete :destroy, {:patient_id => @patient.to_param, :id => @audiogram.to_param},\
            valid_session
        }.to change(Audiogram, :count).by(-1)
      end

      it "redirects to the audiograms list" do
        delete :destroy, {:patient_id => @patient.to_param, :id => @audiogram.to_param},\
          valid_session
#        response.should redirect_to(@audiograms_url)
#        response.should redirect_to([@patient, @audiograms_url])
        expect(response).to redirect_to(patient_audiograms_url)
      end
    end
  end

  describe "POST direct_create" do
    # POST /audiograms/direct_create
    # params は params[:hp_id][:datatype][:examdate][:audiometer][:comment][:data]
    # datatype は今のところ audiogram, impedance, images

    before do
      @valid_hp_id = 19
      @invalid_hp_id = 18
      @examdate = Time.now.strftime("%Y:%m:%d-%H:%M:%S")
      @audiometer = "audiometer"
      @datatype = "audiogram"
      @comment = "comment"
      @raw_audiosample = "7@/          /  080604  //   0   30 ,  10   35 ,  20   40 ,          ,  30   45 ,          ,  40   50 ,          ,  50   55 ,          ,  60   60 ,          , -10   55 ,  -5   55 ,          ,   0   55 ,          ,   5   55 ,          ,  10   55 ,          ,  15   55 ,  4>  4<,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,/P"
      #  125 250 500  1k  2k  4k  8k
      #R   0  10  20  30  40  50  60
      #L  30  35  40  45  50  55  60
    end

    context "datatypeがない場合" do
      it "HTTP status code 400を返すこと" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
	                      :audiometer => @audiometer, :comment => @comment, :data => @raw_audiosample}
        expect(response.status).to be(400)
      end
    end

    context "datatypeがaudiogramの場合" do
      it "正しいパラメータの場合、Audiogramのアイテム数が1増えること" do
        expect {
          post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                                :audiometer => @audiometer, :datatype => @datatype, \
                                :comment => @comment, :data => @raw_audiosample}
        }.to change(Audiogram, :count).by(1)
      end

      it "正しいパラメータの場合、maskingのデータが取得されること" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                              :audiometer => @audiometer, :datatype => @datatype, \
                              :comment => @comment, :data => @raw_audiosample}
        expect(assigns(:audiogram).mask_ac_rt_125).not_to be_nil
      end

      it "正しいパラメータの場合、HTTP status code 204を返すこと" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                              :audiometer => @audiometer, :datatype => @datatype, \
                              :comment => @comment, :data => @raw_audiosample}
        expect(response.status).to be(204)
      end

      it "正しいパラメータの場合、所定の位置にグラフとサムネイルが作られること" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                              :audiometer => @audiometer, :datatype => @datatype, \
                              :comment => @comment, :data => @raw_audiosample}
        img_loc = "app/assets/images/#{assigns(:audiogram).image_location}"
        thumb_loc = img_loc.sub("graphs", "thumbnails")
        expect(File::exists?(img_loc)).to be true
        expect(File::exists?(thumb_loc)).to be true
        # assigns(:audiogram)を有効にするには、controller側でインスタンス変数@audiogramが
        # 作成したAudiogramを示すことが必要
      end

      if id_validation_enable?
        it "(以前のsystremでは)不正なhp_idの場合、HTTP status code 400を返すこと" do
          post :direct_create, {:hp_id => @invalid_hp_id, :examdate => @examdate, \
                                :audiometer => @audiometer, :datatype => @datatype, \
                                :comment => @comment, :data => @raw_audiosample}
          response.status.should  be(400)
        end
      else
        it "(以前のsystremでは)不正なhp_idの場合も、HTTP status code 204を返すこと" do
          post :direct_create, {:hp_id => @invalid_hp_id, :examdate => @examdate, \
                                :audiometer => @audiometer, :datatype => @datatype, \
                                :comment => @comment, :data => @raw_audiosample}
          expect(response.status).to be(204)
        end
      end

      it "audiometerの入力がない場合、HTTP status code 400を返すこと" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                              :datatype => @datatype, \
                              :comment => @comment, :data => @raw_audiosample}
        expect(response.status).to be(400)
      end

      it "dataがない場合、HTTP status code 400を返すこと" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                              :audiometer => @audiometer, :datatype => @datatype, \
                              :comment => @comment}
        expect(response.status).to be(400)
      end

      it "data形式が不正の場合、HTTP status code 400を返すこと" do
        post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                              :audiometer => @audiometer, :datatype => @datatype, \
                              :comment => @comment, :data => "no valid data"}
        expect(response.status).to be(400)
      end

      it "hp_idが存在しないものの場合、新たにPatientのインスタンスを作る(Patientのアイテム数が1増える)こと" do
        if patient_to_delete = Patient.find_by_hp_id(@valid_hp_id)
          patient_to_delete.destroy
        end
        expect {
          post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                                :audiometer => @audiometer, :datatype => @datatype, \
                                :comment => @comment, :data => @raw_audiosample}
        }.to change(Patient, :count).by(1)
      end

      it "hp_idが存在しないものの場合、(新たにPatientを作成し) Audiogramのアイテム数が1増えること" do
        if patient_to_delete = Patient.find_by_hp_id(@valid_hp_id)
          patient_to_delete.destroy
        end
        expect {
          post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
                                :audiometer => @audiometer, :datatype => @datatype, \
                                :comment => @comment, :data => @raw_audiosample}
        }.to change(Audiogram, :count).by(1)
      end

      context "comment内容による @patient.audiogram.commentの変化について" do
        before do
          @patient.hp_id = valid_id?(@patient.hp_id)
	  @patient.save
	end

        def direct_create_with_comment(com)
          post :direct_create, {:hp_id => @patient.hp_id, :examdate => @examdate, \
                                :audiometer => @audiometer, :datatype => @datatype, \
                                :comment => com, :data => @raw_audiosample}
          @patient.reload
        end

        it "1つのcommentがある場合、それに応じたコメントが記録されること" do
          direct_create_with_comment("RETRY_")
          expect(@patient.audiograms.last.comment).to match(/再検査\(RETRY\)/)
          direct_create_with_comment("MASK_")
          expect(@patient.audiograms.last.comment).to match(/マスキング変更\(MASK\)/)
          direct_create_with_comment("PATCH_")
          expect(@patient.audiograms.last.comment).to match(/パッチテスト\(PATCH\)/)
          direct_create_with_comment("MED_")
          expect(@patient.audiograms.last.comment).to match(/薬剤投与後\(MED\)/)
          direct_create_with_comment("OTHER:幾つかのコメント_")
          expect(@patient.audiograms.last.comment).to match(/^・幾つかのコメント/)
        end

        it "2つのcommentがある場合、それに応じたコメントが記録されること" do
          direct_create_with_comment("RETRY_MASK_")
          expect(@patient.audiograms.last.comment).to match(/再検査\(RETRY\)/)
          expect(@patient.audiograms.last.comment).to match(/マスキング変更\(MASK\)/)
          direct_create_with_comment("MED_OTHER:幾つかのコメント_")
          expect(@patient.audiograms.last.comment).to match(/薬剤投与後\(MED\)/)
          expect(@patient.audiograms.last.comment).to match(/^・幾つかのコメント/)
        end
      end

      it "examdateが設定されていない場合..." do
        skip "どうしたものかまだ思案中"
      end

    end
  end

  describe "PUT edit_comment" do # /patients/:patient_id/audiograms/:id/edit_comment
    before do
      @old_comment = "Old comment"
      @new_comment = "New comment"
      audiogram = Audiogram.create! valid_attributes
      audiogram.comment = @old_comment
      audiogram.save
      @patient.audiograms << audiogram
      @audiogram = @patient.audiograms.first
    end

    it "commentを更新できること" do
      expect(@patient.audiograms.length).to eq 1
      expect(@audiogram.comment).to eq @old_comment
      put :edit_comment, {:patient_id => @patient.to_param, :id => @audiogram.to_param, \
	                  :comment => @new_comment}, valid_session
      expect(@audiogram.reload.comment).to eq @new_comment
    end

    it "redirects to show the audiogram" do
      put :edit_comment, {:patient_id => @patient.to_param, :id => @audiogram.to_param, \
	                  :comment => @new_comment}, valid_session
      expect(response).to redirect_to(patient_audiogram_url)
    end
  end
=end
end
