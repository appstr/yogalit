class TeacherHolidaysController < ApplicationController
  before_action :authenticate_user!

  def new
    @teacher = Teacher.where(user_id: current_user).first
    @teacher_holiday = TeacherHoliday.new
    @teacher_holidays = TeacherHoliday.where(teacher_id: @teacher[:id])
  end

  def create
    teacher = Teacher.where(user_id: current_user).first
    convert_to_date(teacher)
    teacher_holiday = TeacherHoliday.new(teacher_holiday_params)
    teacher_holiday[:teacher_id] = teacher[:id]
    if teacher_holiday.save!
      flash[:notice] = "Your Holiday was created successfully!"
      path = teachers_path
    else
      flash[:notice] = "Your Holiday was not save saved. Please try again."
      path = request.referrer
    end
    return redirect_to path
  end

  def destroy
    teacher = Teacher.where(user_id: current_user).first
    TeacherHoliday.where(id: params[:id], teacher_id: teacher[:id]).first.delete
    return redirect_to request.referrer
  end
  private

  def teacher_holiday_params
    params.require(:teacher_holiday).permit(:holiday_date, :description)
  end

  def convert_to_date(teacher)
    Time.zone = teacher[:timezone]
    separate_date
    params[:teacher_holiday][:holiday_date] = Time.zone.local(@year, @month, @day, 00, 00, 00)
  end

  def separate_date
    split_date = params[:teacher_holiday][:holiday_date].split("/")
    @year = split_date[2].to_i
    @day = split_date[1].to_i
    @month = split_date[0].to_i
  end
end
