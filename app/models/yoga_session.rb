class YogaSession < ActiveRecord::Base
  belongs_to :payment
  belongs_to :student
  belongs_to :teacher
  has_many :reported_yoga_sessions
end
