require File.expand_path '../test_helper.rb', __FILE__

require 'factory_bot'
require './main'
require './lib/id_validation'

describe 'PatientsController' do
  before do
    @valid_id1 = '19'
    @valid_id2 = '27' #35 43 51 60 78 86 94
    @invalid_hp_id = '18'
  end

  # return the minimal set of attributes required to create a valid Patient
  def valid_attributes
    {:hp_id => valid_id?(@valid_id1)}
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

    it "全ての patient が表示されること(shows all patients)" do
      _(@response.ok?).must_equal true
      _(@response.body).must_include "<!-- /patients -->"
      _(@response.body).must_include "#{@patients.length} patient"
      @patients.each do |patient|
         _(@response.body).must_include patient.hp_id
      end
    end

    it 'patients#show への link があること(has a link to patients#show)' do
      @patients.each do |patient|
        _(@response.body).must_include "patients/#{patient.id}"
      end
    end

    it 'patients#destroy への link があること(has a link to patients#destroy)' do
      @patients.each do |patient|
        _(@response.body).must_include "<form action=\"/patients/#{patient.id}\" method=\"POST\">"
        _(@response.body).must_include "<input type=\"hidden\" name=\"_method\" value=\"DELETE\">"
      end
    end

    it 'patients#new への link があること(has a link to patients#new)' do
      _(@response.body).must_include "patients/new"
    end
  end

  describe "GET patients#show (/patients/:id)" do
    before do
      @target_hp_id = valid_id?(@valid_id1) # 0000000019
      Patient.delete_all
      @patient = Patient.create!(hp_id: @target_hp_id)
      get "/patients/#{@patient.id}"
      @response = last_response
    end

    it "指定された patient が表示されること(shows the patient)" do
      _(@response.ok?).must_equal true
      _(@response.body).must_include "<!-- /patients/#{@patient.id} -->"
      _(@response.body).must_include "#{@target_hp_id[0..4]}-#{@target_hp_id[5..9]}" # 00000-00019 を含むか
    end

    it 'patients#index への link があること(has a link to patients#index)' do
      _(@response.body).must_include "patients>"
    end

    describe 'audiogram の表示に関して(about displaying the audiogram:)' do
      def create_audiogram(time, ac_rt_500, ac_rt_1k, ac_rt_2k)
        Audiogram.create!(
          examdate: Time.now, comment: "Comment",
          image_location: "graphs_some_directory",
          ac_rt_500: ac_rt_500, ac_rt_1k: ac_rt_1k, ac_rt_2k: ac_rt_2k,
          ac_lt_500: 15, ac_lt_1k: 25, ac_lt_2k: 35,
          audiometer: "Audiometer", hospital: "Hospital")
      end

      it 'patients が audiogram を持たないときに、No Audiogram と表示されること(shows \'No Audiogram\' when the patient has no audiogram)' do
        @patient.audiograms = []
        get "/patients/#{@patient.id}"
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "No Audiogram"
      end

      it 'patients が 1つの audiogram を持つときに、その Audiogram の情報が表示されること(shows information about the audiogram when the patient has only one audiogram)' do
        @patient.audiograms = []
        @patient.audiograms << create_audiogram(Time.now, 10, 20, 30)
        get "/patients/#{@patient.id}"
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "1 exam"
        _(last_response.body).must_include "R: 20"
      end

      it 'patients が 6つの audiogram を持つときに、最も古い Audiogram の情報が表示されないこと(shows no information about the oldest audiogram, when the patient has 6 audiograms)' do
        @patient.audiograms = []
        t = Time.now
        6.times do |i|
          ofs = 10 * i
          @patient.audiograms << create_audiogram(t + ofs, 10 + ofs, 20 + ofs, 30 + ofs)
        end
        get "/patients/#{@patient.id}"
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "6 exams"
        _(last_response.body).wont_include "R: 20"
      end
    end
  end

  describe "GET patients#new (/patients/new)" do
    it "hp_id の入力を持ち、post /patients へ遷移する form を持つこと(has an input field for hp_id, and a form migrating to \'post /patients\')" do
      get "/patients/new"
      _(last_response.body).must_include "<!-- /patients/new -->"
      _(last_response.body).must_match /form action='\/patients' method='POST'/
      _(last_response.body).must_match /input type='text' name='hp_id'/
    end
  end

  describe "POST patients#create (/patients)" do
    before do
      Patient.delete_all
    end

    describe "valid params を入力した場合(when params are valid)" do
      it "新しく Patient を作成すること(creates a new patient)" do
        patient_num = Patient.all.length
        post "/patients", valid_attributes, valid_session
        _(Patient.all.length).must_equal (patient_num + 1)
      end

      it "redirect されること(redirects)" do
        post "/patients", valid_attributes, valid_session
        _(last_response.redirect?).must_equal true
      end

      it "redirect された先が、作成された patient の view であること(redirects to the view of the created patient)" do
        post "/patients", valid_attributes, valid_session
        follow_redirect!
        _(last_response.ok?).must_equal true
        patient = Patient.last
        _(last_response.body).must_include "<!-- /patients/#{patient.id} -->"
        _(last_response.body).must_include "#{patient.hp_id[0..4]}-#{patient.hp_id[5..9]}" # 00000-00019 を含むか
      end
    end

    describe "valid でない params を入力した場合(when params are not valid)" do
      before do
        @id_validation_tmp = Id_validation::state
        Id_validation::enable  # 設定によらず強制的に validation を有効にしておく
      end

      after do
        @id_validation_tmp ? Id_validation::enable : Id_validation::disable
      end

      it "patients の 数が増えないこと(do not increase the number of patients)" do
        patient_num = Patient.all.length
        post "/patients", :hp_id => 'invalid id' #, valid_session
        _(Patient.all.length).must_equal patient_num
      end

      it "/patients/new の view を表示すること(shows the view of \'/patients/new\')" do
        post "/patients", :hp_id => 'invalid id' #, valid_session
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/new -->"
      end
    end

    describe "hp_id が重複する場合(when collision occurs in hp_id)" do
      it "patients の 数が増えないこと(do not increase the number of patients)" do
        Patient.delete_all
        Patient.create!(hp_id: valid_id?(@valid_id1)) # 0000000019
        patient_num = Patient.all.length
        post "/patients", :hp_id => valid_id?(@valid_id1)
        _(Patient.all.length).must_equal patient_num
      end
    end
  end

  describe "GET patients#edit (/patients/:id/edit)" do
    before do
      Patient.delete_all
      @patient = Patient.create!(hp_id: valid_id?(@valid_id1)) # 0000000019
      get "/patients/#{@patient.id}/edit"
      @response = last_response
    end

    it "指定された patient の編集画面が得られること(shows an editing page of the patient)" do
      _(@response.ok?).must_equal true
      _(@response.body).must_include "<!-- /patients/#{@patient.id}/edit -->"
    end

    it "post /patients へ遷移する form を持つこと(has a form migrating to \'past /patients\')" do
      _(@response.body).must_match Regexp.new("form action=\"/patients/#{@patient.id}\" method=\"POST\"") 
      _(@response.body).must_match Regexp.new("name=\"_method\" value=\"PUT\"") 
      _(@response.body).must_match Regexp.new("input type=\"text\" name=\"hp_id\"")
    end
  end

  describe "PUT patiets#update (/patients/:id)" do
    before do
      Patient.delete_all
      @patient = Patient.create! valid_attributes
    end

    describe "valid params を入力した場合(when params are valid:" do
      it "指定された patient が update されること(updates the patient)" do
        put "/patients/#{@patient.id}", params={hp_id: valid_id?(@valid_id2)} # 000000027
        patient_reloaded = Patient.find(@patient.id)
        _(patient_reloaded.hp_id).wont_equal @patient.hp_id
      end

      it "redirect されること(redirects)" do
        put "/patients/#{@patient.id}", params={hp_id: @patient.hp_id}
        _(last_response.redirect?).must_equal true
      end

      it "redirect された先が、指定された patient の view であること(redirects to a view of the patient)" do
        put "/patients/#{@patient.id}", params={hp_id: @patient.hp_id}
        follow_redirect!
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/#{@patient.id} -->"
      end
    end

    describe "valid でない params を入力した場合(when params are not valid)" do
      it "指定された patient が update されないこと(do not update the patient)" do
        put "/patients/#{@patient.id}", params={hp_id: 'invalid id'}
        patient_reloaded = Patient.find(@patient.id)
        _(patient_reloaded.hp_id).must_equal @patient.hp_id
      end

      it "/patients/:id/edit の view を表示すること(shows a view of /patients/:id/edit)" do
        put "/patients/#{@patient.id}", params={hp_id: 'invalid id'}
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/#{@patient.id}/edit -->"
      end
    end
  end

  describe "DELETE patients#destroy (/patients/:id)" do
    before do
      Patient.delete_all
      @patient = Patient.create! valid_attributes
    end

    it "指定された patient を削除すること(delete the patient)" do
      patient_num = Patient.all.length
      delete "/patients/#{@patient.id}"
      _(Patient.all.length).must_equal (patient_num - 1)
    end

    it "redirect されること(redirects)" do
      delete "/patients/#{@patient.id}"
      _(last_response.redirect?).must_equal true
    end

    it "redirect 先が、全ての patients のリストであること(redirects to the list of all patients)" do
      delete "/patients/#{@patient.id}"
      follow_redirect!
      _(last_response.ok?).must_equal true
      _(last_response.body).must_include "<!-- /patients -->"
    end
  end

  describe "GET patients_by_id (/patients_by_id/:hp_id)" do
    describe "validな hp_idで requestした場合(when requested by a valid hp_id)" do
      before do
        target_hp_id = valid_id?(@valid_id1) # 0000000019
        Patient.delete_all
        @patient = Patient.create! valid_attributes
        @hp_id = @patient.hp_id
        get "/patients_by_id/#{@hp_id}", valid_session
      end

      it "redirect されること(redirects)" do
        _(last_response.redirect?).must_equal true
      end

      it "redirect 先が、指定の patient の view であること(redirects to the view of the patient)" do
        follow_redirect!
        _(last_response.ok?).must_equal true
        _(last_response.body).must_include "<!-- /patients/#{@patient.id} -->"
        _(last_response.body).must_include "#{@hp_id[0..4]}-#{@hp_id[5..9]}" # 00000-00019 を含むか
      end
    end

    it "存在しない、validな hp_idで requestした場合、HTTP status code 404を返すこと(retrun 404 if requested by a valid but not-saved hp_id)" do
      target_hp_id = valid_id?(@valid_id1) # 0000000019
      Patient.delete_all
      patient = Patient.create! valid_attributes
      hp_id = patient.hp_id
      patient.delete
      get "/patients_by_id/#{@hp_id}", valid_session
      _(last_response.status).must_equal 404
    end

    it "validation 有効な時に invalid な hp_id で request した場合は HTTP status code 400 [Bad request] を返すこと(return 400 [Bad request] when requested by invalid hp_id, under enabled validation)" do
      id_validation_tmp = Id_validation::state
      Id_validation::enable  # 設定によらず強制的に validation を有効にしておく
      get "/patients_by_id/#{@invalid_hp_id}", valid_session
      _(last_response.status).must_equal 400
      id_validation_tmp ? Id_validation::enable : Id_validation::disable
    end
  end

  describe "POST patients_by_id_create_exam (/patients_by_id/:hp_id/create_exam)" do
    # params は params[:datatype][:examdate][:equip_name][:comment][:data]
    # equip_name は検査機器の名称: 'AA-97' など
    # datatype は今のところ audiogram, impedance, images
    let(:valid_audio_attributes) { {datatype: @datatype, examdate: @examdate, \
                                    equip_name: @equip_name, comment: @comment, \
                                    data: @raw_audiosample} }
    let(:audio_attributes_wo_datatype) { {examdate: @examdate, equip_name: @equip_name, \
                                    comment: @comment, data: @raw_audiosample} }
    let(:audio_attributes_wo_equip_name) { {datatype: @datatype, examdate: @examdate, \
                                    comment: @comment, data: @raw_audiosample} }
    let(:audio_attributes_wo_data) { {datatype: @datatype, examdate: @examdate, \
                                    equip_name: @equip_name, comment: @comment} }
    let(:audio_attributes_w_invalid_data) { {datatype: @datatype, examdate: @examdate, \
                                    equip_name: @equip_name, comment: @comment, \
                                    data: "no valid data"} }

    before do
      @valid_hp_id = @valid_id1
      @examdate = Time.now.strftime("%Y:%m:%d-%H:%M:%S")
      @comment = "comment"
      Patient.delete_all
    end

    describe "audiometer のデータが送られた場合(when an audiogram data was send}" do
      before do
        @equip_name = "audiometer"
        @datatype = "audiogram"
        @raw_audiosample = "7@/          /  080604  //   0   30 ,  10   35 ,  20   40 ,          ,  30   45 ,          ,  40   50 ,          ,  50   55 ,          ,  60   60 ,          , -10   55 ,  -5   55 ,          ,   0   55 ,          ,   5   55 ,          ,  10   55 ,          ,  15   55 ,  4>  4<,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,        ,  4>  4<,/P"
        #  125 250 500  1k  2k  4k  8k
        #R   0  10  20  30  40  50  60
        #L  30  35  40  45  50  55  60
      end

      it "datatypeがない場合 HTTP status code 400 [Bad request] を返すこと(return 400 [Bad request] without \'datatype\')" do
        post "/patients_by_id/#{@valid_hp_id}/create_exam", audio_attributes_wo_datatype
        _(last_response.status).must_equal 400
      end

      describe "datatypeがaudiogramの場合(when \'datatype\' is \'audiogram\')" do
        it "正しいパラメータの場合、Audiogramのアイテム数が1増えること(increase the number of Audiograms if params are regular)" do
          audiogram_num = Audiogram.all.length
          post "/patients_by_id/#{@valid_hp_id}/create_exam", valid_audio_attributes
          _(Audiogram.all.length).must_equal (audiogram_num + 1)
        end

        it "正しいパラメータの場合、maskingのデータが取得されること(can get masking data if params are regular)" do
          post "/patients_by_id/#{@valid_hp_id}/create_exam", valid_audio_attributes
          _(Audiogram.last.mask_ac_rt_125).wont_equal nil
        end

        it "正しいパラメータの場合、HTTP status code 204 [No content] を返すこと(return 204 [No content] if params are regular)" do
          post "/patients_by_id/#{@valid_hp_id}/create_exam", valid_audio_attributes
          _(last_response.status).must_equal 204
        end

        it "正しいパラメータの場合、所定の位置にグラフとサムネイルが作られること(create a graph and its thumbnail in appropriate location if params are regular)" do
          post "/patients_by_id/#{@valid_hp_id}/create_exam", valid_audio_attributes
          img_loc = "assets/images/#{Audiogram.last.image_location}"
          thumb_loc = img_loc.sub("graphs", "thumbnails")
          _(File::exist?(img_loc)).must_equal true
          _(File::exist?(thumb_loc)).must_equal true
        end

        describe "invalid な ID でリクエストした場合(when requested by invalid ID)" do
          it "ID valdationが有効な場合、HTTP status code 400 [Bad request] を返すこと(return 400 [Bad request] if ID validation is enable)" do
            id_validation_tmp = Id_validation::state
            Id_validation::enable
            post "/patients_by_id/#{@invalid_hp_id}/create_exam", valid_audio_attributes
            id_validation_tmp ? Id_validation::enable : Id_validation::disable
            _(last_response.status).must_equal 400
          end

          it "ID valdationが無効な場合、HTTP status code 204 [No content] を返すこと(return 204 [No content] if ID validation is enable)" do
            id_validation_tmp = Id_validation::state
            Id_validation::disable
            post "/patients_by_id/#{valid_id?(@invalid_hp_id)}/create_exam", valid_audio_attributes
            id_validation_tmp ? Id_validation::enable : Id_validation::disable
            _(last_response.status).must_equal 204
          end
        end

        it "equip_nameの入力がない場合、HTTP status code 400を返すこと(return 400 [Bad request] if equip_name was not given)" do
          post "/patients_by_id/#{@valid_hp_id}/create_exam", audio_attributes_wo_equip_name
          _(last_response.status).must_equal 400
        end

        it "dataがない場合、HTTP status cod@e 400を返すこと(return 400 [Bad request] if no data was given)" do
          post "/patients_by_id/#{@valid_hp_id}/create_exam", audio_attributes_wo_data
          _(last_response.status).must_equal 400
        end

        it "data形式が不正の場合、HTTP status code 400を返すこと(return 400 [Bad request] if data was irregular)" do
          post "/patients_by_id/#{@valid_hp_id}/create_exam", audio_attributes_w_invalid_data
          _(last_response.status).must_equal 400
        end

        describe "hp_idが存在しない場合(when the hp_id was not saved:)" do
          before do
            Patient.delete_all
            @patient_num = Patient.all.length
            @audiogram_num = Audiogram.all.length
            post "/patients_by_id/#{@valid_hp_id}/create_exam", valid_audio_attributes
          end

          it "新たにPatientのインスタンスを作る(Patientのアイテム数が1増える)こと(create a new Patient instance)" do
            _(Patient.all.length).must_equal (@patient_num + 1)
          end

          it "(新たにPatientを作成し) Audiogramのアイテム数が1増えること(increase the number of audiograms" do
            _(Audiogram.all.length).must_equal (@audiogram_num + 1)
          end
        end

        describe "comment内容による @patient.audiogram.commentの変化について(about @patient.audiogram.comment:)" do
          before do
            Patient.delete_all
            @patient = Patient.create! valid_attributes
          end

          def create_with_comment(com)
            post "/patients_by_id/#{valid_id?(@patient.hp_id)}/create_exam",
                                              {datatype: @datatype, examdate: @examdate, \
                                               equip_name: @equip_name, comment: com, \
                                               data: @raw_audiosample} 
            @patient.reload
          end

          it "1つのcommentがある場合、それに応じたコメントが記録されること(records an adequate comment if one comment was given)" do
            create_with_comment("RETRY_")
            _(@patient.audiograms.last.comment).must_match /再検査\(RETRY\)/
            create_with_comment("MASK_")
            _(@patient.audiograms.last.comment).must_match /マスキング変更\(MASK\)/
            create_with_comment("PATCH_")
            _(@patient.audiograms.last.comment).must_match /パッチテスト\(PATCH\)/
            create_with_comment("MED_")
            _(@patient.audiograms.last.comment).must_match /薬剤投与後\(MED\)/
            create_with_comment("OTHER:幾つかのコメント_")
            _(@patient.audiograms.last.comment).must_match /^・幾つかのコメント/
          end

          it "2つのcommentがある場合、それに応じたコメントが記録されること(records adequate comments if 2 comments were given)" do
            create_with_comment("RETRY_MASK_")
            _(@patient.audiograms.last.comment).must_match /再検査\(RETRY\)/
            _(@patient.audiograms.last.comment).must_match /マスキング変更\(MASK\)/
            create_with_comment("MED_OTHER:幾つかのコメント_")
            _(@patient.audiograms.last.comment).must_match /薬剤投与後\(MED\)/
            _(@patient.audiograms.last.comment).must_match /^・幾つかのコメント/
          end
        end

#        it "examdateが設定されていない場合..." do
#          skip "どうしたものかまだ思案中"
#        end

      end
    end
  end
end
