class StudentsController < ApplicationController
  before_action :authenticate_user!
  def new
    @student = Student.new
    return redirect_to students_path if Student.student_exists?(current_user)
  end

  def create
    student = Student.new(student_params)
    student[:user_id] = current_user[:id]
    if student.save!
      flash[:notice] = "Your Student information was saved!"
      path = students_path
    else
      flash[:notice] = "Your Student information was not saved."
      path = request.referrer
    end
    return redirect_to path
  end

  def index
    @student = Student.where(user_id: current_user).first
  end

  def edit
    @student = Student.find(params[:id])
  end

  def update
    student = Student.find(params[:id])
    student[:first_name] = params[:student][:first_name].downcase
    student[:last_name] = params[:student][:last_name].downcase
    student[:phone] = params[:student][:phone]
    if student.save!
      flash[:notice] = "Your profile info was update successfully!"
      path = students_path
    else
      flash[:notice] = "Your profile info was not updated."
      path = request.referrer
    end
    return redirect_to path
  end

  private

  def student_params
    params.require(:student).permit(:user_id, :first_name, :last_name, :phone)
  end
end
