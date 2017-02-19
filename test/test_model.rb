ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
#require 'rack/test'
require 'factory_girl'
require './models'

#FactoryGirl.definition_file_paths = [File.expand_path('../', __FILE__)]
FactoryGirl.find_definitions

describe Patient do
  describe "hp_id が valid の場合" do
    it "保存できること" do
      patient = FactoryGirl.build(:patient) # hp_id: 19(valid)
      patient.save.must_equal true
    end
  end

  if id_validation_enable?
    describe "validation が有効で(models.rbで設定)、hp_id が invalid の場合" do
      it "保存できないこと" do
        patient = FactoryGirl.build(:patient, :hp_id => '123')
                                              # hp_id: 123 (invalid)
        patient.save.wont_equal true
      end
    end
  end
end

describe Audiogram do
  describe "valid data の場合" do
    it "保存できること" do
      audiogram = FactoryGirl.build(:audiogram)
      audiogram.save.must_equal true
    end
  end

  describe "examdate がない場合" do
    it "保存できないこと" do
      audiogram = FactoryGirl.build(:audiogram, :examdate => nil)
      audiogram.save.wont_equal true
    end
  end

  describe "audiometer がない場合" do
    it "保存できないこと" do
      audiogram = FactoryGirl.build(:audiogram, :audiometer => nil)
      audiogram.save.wont_equal true
    end
  end
end
