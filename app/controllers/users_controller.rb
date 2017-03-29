class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user[:teacher_or_student] == "teacher"
      teacher = Teacher.where(user_id: current_user).first
      if teacher.nil?
        path = new_teacher_path
      else
        path = teachers_path
      end
    elsif current_user[:teacher_or_student] == "student"
      student = Student.where(user_id: current_user).first
      if student.nil?
        path = new_student_path
      else
        path = students_path
      end
    end
    return redirect_to path
  end

end
