require 'sinatra/base'
require 'sinatra/activerecord'

def id_validation_enable?
  true # or false
end

class Patient < ActiveRecord::Base
  validate :hp_id_is_valid
end

def hp_id_is_valid
  require './lib/id_validation'
  unless valid_id?(self.hp_id)
    errors.add(:hp_id, "Invalid ID")
  end
end
