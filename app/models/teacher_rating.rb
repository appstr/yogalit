class TeacherRating < ActiveRecord::Base
  belongs_to :yoga_session
  belongs_to :teacher
end
