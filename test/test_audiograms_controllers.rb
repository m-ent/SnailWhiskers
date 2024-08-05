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
      _(@response.body).must_match /1 audiogram[^s]/
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
      _(@response.body).must_match /<input type.+button.+onclick.+print()/
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

=begin
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

end
