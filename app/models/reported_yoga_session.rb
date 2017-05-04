class ReportedYogaSession < ActiveRecord::Base
  belongs_to :student
  belongs_to :teacher
  belongs_to :yoga_session
end
