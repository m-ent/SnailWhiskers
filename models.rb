require 'sinatra/base'
require 'sinatra/activerecord'

def id_validation_enable?
  true
end

class Patient < ActiveRecord::Base
  def save
    true
  end
end
