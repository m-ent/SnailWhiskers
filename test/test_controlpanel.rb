require File.expand_path '../test_helper.rb', __FILE__

require './main'

describe "GET controlpanel (/controlpanel) : view" do
  before do
    get "/controlpanel"
    @response = last_response
  end

  it "audiograms/all_rebuild への link が含まれること(has a link to audiograms#all_rebuild)" do
    _(@response.body).must_include "audiograms/all_rebuild"
  end

  it "audiograms/new への link が含まれること(has a link to audiograms#new)" do
    _(@response.body).must_include "audiograms/new"
  end

  it "audiograms/exam_of_the_day への link が含まれること(has a link to audiograms#exams_of_the_day)" do
    _(@response.body).must_include "audiograms/exams_of_the_day"
  end
end

