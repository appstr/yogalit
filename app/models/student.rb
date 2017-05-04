class Student < ActiveRecord::Base
  belongs_to :user
  has_many :yoga_sessions
  has_many :favorite_teachers
  has_many :reported_yoga_sessions

  def self.student_exists?(current_user)
    return Student.where(user_id: current_user).first.nil? ? false : true
  end
end
