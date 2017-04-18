require 'sinatra/base'
require 'sinatra/activerecord'

def id_validation_enable?
  true # or false
end

def hp_id_is_valid
  require './lib/id_validation'
  unless valid_id?(self.hp_id)
    errors.add(:hp_id, "Invalid ID")
  end
end

class Patient < ActiveRecord::Base
  has_many :audiograms
  validate :hp_id_is_valid
end

class Audiogram < ActiveRecord::Base
  belongs_to :patient
  validates_presence_of :examdate, :audiometer, :on => [:create, :update]
end
