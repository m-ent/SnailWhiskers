require File.expand_path '../test_helper.rb', __FILE__

require './main'

describe "GET controlpanel (/controlpanel) : view" do
  it "audiograms/all_rebuild への link が含まれること(has a link to audiograms#all_rebuild)" do
    get "/controlpanel"
    @response = last_response
    _(@response.body).must_include "audiograms/all_rebuild"
  end
end

