require 'sinatra/base'
require 'sinatra/activerecord'

class Id_validation
  @@state = true
  def self.state; @@state; end
  def self.enable; @@state = true; end
  def self.disable; @@state = false; end
end

def hp_id_is_valid
  require './lib/id_validation'
  unless valid_id?(self.hp_id)
    errors.add(:hp_id, "Invalid ID")
  end
end

class Patient < ActiveRecord::Base
  has_many :audiograms
  #validate :hp_id_is_valid
  validates :hp_id, uniqueness: true
end

class Audiogram < ActiveRecord::Base
  belongs_to :patient
  validates_presence_of :examdate, :audiometer, :on => [:create, :update]
end
