class YogaSession < ActiveRecord::Base
  belongs_to :payment
  belongs_to :student
  belongs_to :teacher
end
