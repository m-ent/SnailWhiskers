require File.expand_path '../test_helper.rb', __FILE__

require 'factory_girl'
require './models'
require './lib/id_validation'

#FactoryGirl.definition_file_paths = [File.expand_path('../', __FILE__)]
FactoryGirl.find_definitions

describe Patient do
  before do
    Patient.all.each do |p|
      p.destroy
    end
  end

  describe "hp_id が valid の場合" do
    it "保存できること" do
      patient = FactoryGirl.build(:patient) # hp_id: 19(valid)
      patient.save.must_equal true
    end
  end

  describe "hp_id が invalid の場合" do
    it "validation 有効の時は保存できないこと" do
      id_validation_tmp = Id_validation::state
      Id_validation::enable
      patient = FactoryGirl.build(:patient, :hp_id => '123') # hp_id: 123 (invalid)
      patient.save.wont_equal true
      id_validation_tmp ? Id_validation::enable : Id_validation::disable
    end

    it "validation 無効の時は保存できること" do
      id_validation_tmp = Id_validation::state
      Id_validation::disable
      patient = FactoryGirl.build(:patient, :hp_id => '123') # hp_id: 123 (invalid)
      patient.save.must_equal true
      id_validation_tmp ? Id_validation::enable : Id_validation::disable
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
