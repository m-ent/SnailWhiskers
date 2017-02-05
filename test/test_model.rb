require 'minitest/autorun'
require './models'

describe Patient do
  describe "hp_id が valid の場合" do
    it "保存できること" do
      patient = FactoryGirl.build(:patient) # hp_id: 19(valid)
      patient.save.must_equal true
    end
  end

  describe "hp_id が invalid の場合" do
    if id_validation_enable?
      it "保存できないこと" do
        patient = FactoryGirl.build(:patient, :hp_id => '123')
                                              # hp_id: 123 (invalid)
        patient.save.wont_equal true
      end
    else
      it "保存できること" do
        patient = FactoryGirl.build(:patient, :hp_id => '123')
                                   # hp_id: 123 (以前のsystemではinvalid)
        patient.save.must_equal true
      end
    end
  end
end
