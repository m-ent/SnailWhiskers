require File.expand_path '../test_helper.rb', __FILE__

require 'factory_girl'
require './main'
require './lib/id_validation'

describe 'PatientsController' do

  # return the minimal set of attributes required to create a valid Patient
  def valid_attributes
    {:hp_id => valid_id?('19')}
  end

  # return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PatientsController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET patients#index (/patients)" do
    before do
      @patients = Patient.all
      get '/patients'
      @response = last_response
    end

    it "全ての patient が表示されること" do
      @response.ok?.must_equal true
      @response.body.must_include "#{@patients.length} patient"
      @patients.each do |patient|
        @response.body.must_include patient.hp_id
      end
    end

    it 'patients#show への link があること' do
      @patients.each do |patient|
        @response.body.must_include "patients/#{patient.id}"
      end
    end

    it 'patients#destroy への link があること' do
      @patients.each do |patient|
        @response.body.must_include "<form action=\"/patients/#{patient.id}\" method=\"POST\">"
        @response.body.must_include "<input type=\"hidden\" name=\"_method\" value=\"DELETE\">"
      end
    end

    it 'patients#new への link があること' do
      @patients.each do |patient|
        @response.body.must_include "patients/new"
      end
    end
  end

end


=begin
  describe "GET show" do
    it "assigns the requested patient as @patient" do
      patient = Patient.create! valid_attributes
      get :show, {:id => patient.to_param}, valid_session
      expect(assigns(:patient)).to eq(patient)
    end
  end

  describe "GET new" do
    it "assigns a new patient as @patient" do
      get :new, {}, valid_session
      expect(assigns(:patient)).to be_a_new(Patient)
    end
  end

  describe "GET edit" do
    it "assigns the requested patient as @patient" do
      patient = Patient.create! valid_attributes
      get :edit, {:id => patient.to_param}, valid_session
      expect(assigns(:patient)).to eq(patient)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Patient" do
        expect {
          post :create, {:patient => valid_attributes}, valid_session
        }.to change(Patient, :count).by(1)
      end

      it "assigns a newly created patient as @patient" do
        post :create, {:patient => valid_attributes}, valid_session
        expect(assigns(:patient)).to be_a(Patient)
        expect(assigns(:patient)).to be_persisted
      end

      it "redirects to the created patient" do
        post :create, {:patient => valid_attributes}, valid_session
        expect(response).to redirect_to(Patient.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved patient as @patient" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Patient).to receive(:save).and_return(false)
        post :create, {:patient => {}}, valid_session
        expect(assigns(:patient)).to be_a_new(Patient)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Patient).to receive(:save).and_return(false)
        post :create, {:patient => {}}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested patient" do
        patient = Patient.create! valid_attributes
        # Assuming there are no other patients in the database, this
        # specifies that the Patient created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        expect_any_instance_of(Patient).to receive(:update).with({'hp_id' => 'params'})
        put :update, {:id => patient.to_param, :patient => {'hp_id' => 'params'}}, valid_session
      end

      it "assigns the requested patient as @patient" do
        patient = Patient.create! valid_attributes
        put :update, {:id => patient.to_param, :patient => valid_attributes}, valid_session
        expect(assigns(:patient)).to eq(patient)
      end

      it "redirects to the patient" do
        patient = Patient.create! valid_attributes
        put :update, {:id => patient.to_param, :patient => valid_attributes}, valid_session
        expect(response).to redirect_to(patient)
      end
    end

    describe "with invalid params" do
      it "assigns the patient as @patient" do
        patient = Patient.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Patient).to receive(:save).and_return(false)
        put :update, {:id => patient.to_param, :patient => {}}, valid_session
        expect(assigns(:patient)).to eq(patient)
      end

      it "re-renders the 'edit' template" do
        patient = Patient.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Patient).to receive(:save).and_return(false)
        put :update, {:id => patient.to_param, :patient => {}}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested patient" do
      patient = Patient.create! valid_attributes
      expect {
        delete :destroy, {:id => patient.to_param}, valid_session
      }.to change(Patient, :count).by(-1)
    end

    it "redirects to the patients list" do
      patient = Patient.create! valid_attributes
      delete :destroy, {:id => patient.to_param}, valid_session
      expect(response).to redirect_to(patients_url)
    end
  end

  describe "GET by_hp_id" do
    context "validな hp_idで requestした場合" do
      before do
        @patient = Patient.create! valid_attributes
        @hp_id = @patient.hp_id
        get :by_hp_id, {:hp_id => @hp_id}, valid_session
      end

      it "正しく @patientとしてassignされること" do
        expect(assigns(:patient)).to eq(@patient)
      end

      it "redirects to the patient" do
        expect(response).to redirect_to(@patient)
      end
    end

    it "存在しない、validな hp_idで requestした場合、HTTP status code 404を返すこと" do
      patient = Patient.create! valid_attributes
      hp_id = patient.hp_id
      patient.delete
      get :by_hp_id, {:hp_id => hp_id}, valid_session
      expect(response.status).to be(404)
    end

    if id_validation_enable?
      it "(以前のsystemでは)invalidな hp_idで requestした場合、HTTP status code 400を返すこと" do
        @invalid_hp_id = 18
        get :by_hp_id, {:hp_id => @invalid_hp_id}, valid_session
        expect(response.status).to be(400)
      end
    else
      it "(以前のsystemでは)invalidな hp_idで requestした場合も、HTTP status code 400を返さないこと" do
        @invalid_hp_id = 18
        get :by_hp_id, {:hp_id => @invalid_hp_id}, valid_session
        expect(response.status).not_to be(400)
      end
    end
  end

  describe "POST direct_create" do
    # POST /patients/direct_create
    # params は params[:hp_id][:datatype][:examdate][:equip_name][:comment][:data]
    # equip_name は検査機器の名称: 'AA-97' など
    # datatype は今のところ audiogram, impedance, images
    let(:valid_audio_attributes) { {:hp_id => @valid_hp_id, \
                                    :datatype => @datatype, \
                                    :examdate => @examdate, \
                                    :equip_name => @equip_name, \
                                    :comment => @comment, \
                                    :data => @raw_audiosample} }
    let(:audio_attributes_wo_datatype) { {:hp_id => @valid_hp_id, \
                                    :examdate => @examdate, \
                                    :equip_name => @equip_name, \
                                    :comment => @comment, \
                                    :data => @raw_audiosample} }
    let(:audio_attributes_w_invalidID) { {:hp_id => @invalid_hp_id, \
                                    :datatype => @datatype, \
                                    :examdate => @examdate, \
                                    :equip_name => @equip_name, \
                                    :comment => @comment, \
                                    :data => @raw_audiosample} }
    let(:audio_attributes_wo_equip_name) { {:hp_id => @valid_hp_id, \
                                    :datatype => @datatype, \
                                    :examdate => @examdate, \
                                    :comment => @comment, \
                                    :data => @raw_audiosample} }
    let(:audio_attributes_wo_data) { {:hp_id => @valid_hp_id, \
                                    :datatype => @datatype, \
                                    :examdate => @examdate, \
                                    :equip_name => @equip_name, \
                                    :comment => @comment} }
    let(:audio_attributes_w_invalid_data) { {:hp_id => @valid_hp_id, \
                                    :datatype => @datatype, \
                                    :examdate => @examdate, \
                                    :equip_name => @equip_name, \
                                    :comment => @comment, \
                                    :data => "no valid data"} }

    before do
      @valid_hp_id = 19
      @invalid_hp_id = 18
      @examdate = Time.now.strftime("%Y:%m:%d-%H:%M:%S")
      @comment = "comment"
    end

    context "audiometer のデータが送られた場合" do
      before do
        @equip_name = "audiometer"
        @datatype = "audiogram"
        @raw_audiosample = "7@/          /  080604  //   0   30 ,  10   35 ,  20   40 ,          ,  30   45 ,          ,  40   50 ,          ,  50   55 ,          ,  60   60 ,          , -10   55 ,  -5   55 ,          ,   0   55 ,          ,   5   55 ,          ,  10   55 ,          ,  15   55 ,  4>  4<,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,/P"
        #  125 250 500  1k  2k  4k  8k
        #R   0  10  20  30  40  50  60
        #L  30  35  40  45  50  55  60
      end

      context "datatypeがない場合" do
        it "HTTP status code 400を返すこと" do
#puts "-------------------------------------"
#p valid_audio_attributes
#          post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
#                   :equip_name => @equip_name, :comment => @comment, \
#                   :data => @raw_audiosample}
          post :direct_create, audio_attributes_wo_datatype
          expect(response.status).to be(400)
        end
      end

      context "datatypeがaudiogramの場合" do
        it "正しいパラメータの場合、Audiogramのアイテム数が1増えること" do
          expect {
            post :direct_create, valid_audio_attributes
          }.to change(Audiogram, :count).by(1)
        end

        it "正しいパラメータの場合、maskingのデータが取得されること" do
          post :direct_create, valid_audio_attributes
          expect(assigns(:audiogram).mask_ac_rt_125).not_to be_nil
        end

        it "正しいパラメータの場合、HTTP status code 204を返すこと" do
          post :direct_create, valid_audio_attributes
          expect(response.status).to be(204)
        end

        it "正しいパラメータの場合、所定の位置にグラフとサムネイルが作られること" do
          post :direct_create, valid_audio_attributes
          img_loc = "app/assets/images/#{assigns(:audiogram).image_location}"
          thumb_loc = img_loc.sub("graphs", "thumbnails")
          expect(File::exists?(img_loc)).to be true
          expect(File::exists?(thumb_loc)).to be true
          # assigns(:audiogram)を有効にするには、controller側でインスタンス変数@audiogramが
          # 作成したAudiogramを示すことが必要
        end

        if id_validation_enable?
          it "(以前のsystremでは)不正なhp_idの場合、HTTP status code 400を返すこと" do
            post :direct_create, audio_attributes_w_invalidID
            response.status.should  be(400)
          end
        else
          it "(以前のsystremでは)不正なhp_idの場合も、HTTP status code 204を返すこと" do
            post :direct_create, audio_attributes_w_invalidID
            expect(response.status).to be(204)
          end
        end

        it "equip_nameの入力がない場合、HTTP status code 400を返すこと" do
          post :direct_create, audio_attributes_wo_equip_name
#          post :direct_create, {:hp_id => @valid_hp_id, :examdate => @examdate, \
#                   :datatype => @datatype, \
#                   :comment => @comment, :data => @raw_audiosample}
          expect(response.status).to be(400)
        end

        it "dataがない場合、HTTP status code 400を返すこと" do
          post :direct_create, audio_attributes_wo_data
          expect(response.status).to be(400)
        end

        it "data形式が不正の場合、HTTP status code 400を返すこと" do
          post :direct_create, audio_attributes_w_invalid_data
          expect(response.status).to be(400)
        end

        it "hp_idが存在しないものの場合、新たにPatientのインスタンスを作る(Patientのアイテム数が1増える)こと" do
          if patient_to_delete = Patient.find_by_hp_id(@valid_hp_id)
            patient_to_delete.destroy
          end
          expect {
            post :direct_create, valid_audio_attributes
          }.to change(Patient, :count).by(1)
        end

        it "hp_idが存在しないものの場合、(新たにPatientを作成し) Audiogramのアイテム数が1増えること" do
          if patient_to_delete = Patient.find_by_hp_id(@valid_hp_id)
            patient_to_delete.destroy
          end
          expect {
            post :direct_create, valid_audio_attributes
          }.to change(Audiogram, :count).by(1)
        end

        context "comment内容による @patient.audiogram.commentの変化について" do
          before do
            @patient = Patient.create! valid_attributes
          end

          def direct_create_with_comment(com)
            post :direct_create, {:hp_id => @patient.hp_id, :examdate => @examdate, \
                          :equip_name => @equip_name, :datatype => @datatype, \
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
  end

end



=end
