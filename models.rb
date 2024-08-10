require 'sinatra/base'
require 'sinatra/activerecord'
require_relative 'lib/id_validation'

def hp_id_is_valid
  if Id_validation::state
    unless valid_id?(self.hp_id)
      errors.add(:hp_id, "Invalid ID")
    end
  else
    true
  end
end

class Patient < ActiveRecord::Base
  has_many :audiograms
  validate :hp_id_is_valid
  validates :hp_id, uniqueness: true
end

class Audiogram < ActiveRecord::Base
  belongs_to :patient
  validates_presence_of :examdate, :audiometer, :on => [:create, :update]
end
