class TeacherHolidaysController < ApplicationController
  before_action :authenticate_user!

  def new
    @teacher = Teacher.where(user_id: current_user).first
    @teacher_holiday = TeacherHoliday.new
    @teacher_holidays = TeacherHoliday.where(teacher_id: @teacher[:id])
  end

  def create
    teacher = Teacher.where(user_id: current_user).first
    Time.zone = teacher[:timezone]
    holiday_range = params[:teacher_holiday][:holiday_date_range].split(" - ")
    split_start_date(holiday_range[0])
    split_end_date(holiday_range[1])
    params[:teacher_holiday][:holiday_date_range] = (Time.zone.local(@start_year, @start_month, @start_day, 00, 00, 00).to_i..Time.zone.local(@end_year, @end_month, @end_day, 23, 59, 00).to_i)
    teacher_holiday = TeacherHoliday.new
    teacher_holiday[:teacher_id] = teacher[:id]
    teacher_holiday[:holiday_date_range] = params[:teacher_holiday][:holiday_date_range]
    teacher_holiday[:description] = params[:teacher_holiday][:description]
    if teacher_holiday.save!
      flash[:notice] = "Your Holiday was created successfully!"
      path = teachers_path(section: "holidays")
    else
      flash[:notice] = "Your Holiday was not save saved. Please try again."
      path = teachers_path(section: "holidays")
    end
    return redirect_to path
  end

  def destroy
    teacher = Teacher.where(user_id: current_user).first
    TeacherHoliday.where(id: params[:id], teacher_id: teacher[:id]).first.delete
    return redirect_to teachers_path(section: "holidays")
  end

  private

  def split_start_date(start_date)
    split_date = start_date.split("/")
    @start_year = split_date[2].to_i
    @start_month = split_date[0].to_i
    @start_day = split_date[1].to_i
  end

  def split_end_date(end_date)
    split_date = end_date.split("/")
    @end_year = split_date[2].to_i
    @end_month = split_date[0].to_i
    @end_day = split_date[1].to_i
  end
end
