class Student < ActiveRecord::Base
  belongs_to :user
  has_many :favorite_teachers

  def self.student_exists?(current_user)
    return Student.where(user_id: current_user).first.nil? ? false : true
  end
end
