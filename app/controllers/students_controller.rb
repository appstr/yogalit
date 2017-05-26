class StudentsController < ApplicationController
  before_action :authenticate_user!
  include ApplicationHelper

  def new
    @student = Student.new
    return redirect_to students_path if Student.student_exists?(current_user)
  end

  def create
    return redirect_to students_path if Student.student_exists?(current_user)
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
    @upcoming_yoga_sessions = get_upcoming_yoga_sessions
    @favorite_teachers = get_favorite_teachers
    @most_recent_yoga_sessions = get_most_recent_yoga_sessions
  end

  def get_most_recent_yoga_sessions
    recent_booked_times = []
    booked_times = TeacherBookedTime.where(student_id: @student).where("session_date >= ? AND session_date <= ?", Date.today - 1, Date.today + 1)
    booked_times.each do |bt|
      Time.zone = bt[:teacher_timezone]
      split_date_and_time(bt)
      teacher_start_time = Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00)
      if teacher_start_time.in_time_zone(bt[:student_timezone]) > (Time.now.in_time_zone(bt[:student_timezone]) - 86400) && Time.now.in_time_zone(bt[:student_timezone]) < (teacher_start_time.in_time_zone(bt[:student_timezone]) + 86400)
        recent_booked_times << bt
      end
    end
    return get_most_recent_sessions_info(recent_booked_times) if !recent_booked_times.empty?
    return nil
  end

  def get_most_recent_sessions_info(recent_booked_times)
    most_recent = {}
    counter = 1
    recent_booked_times.each do |bt|
      yoga_session = YogaSession.where(teacher_booked_time_id: bt).first
      next if yoga_session.nil?
      teacher = Teacher.find(yoga_session[:teacher_id])
      time_range = sanitize_date_range_for_view(bt[:time_range], bt[:student_timezone])
      split_date = bt[:session_date].to_s.split("-")
      Time.zone = bt[:teacher_timezone]
      split_time_range = time_range.split(" - ")
      start_time = sanitize_date_for_time_only(Time.parse(split_time_range[0]).in_time_zone(bt[:student_timezone]))
      end_time = sanitize_date_for_time_only((Time.parse(split_time_range[1]) - 1).in_time_zone(bt[:student_timezone]))
      timestamp_time = Time.parse(split_time_range[0]).in_time_zone(bt[:teacher_timezone])
      timestamp = Time.zone.local(split_date[0], split_date[1], split_date[2], timestamp_time.strftime("%k"), timestamp_time.strftime("%M"))
      most_recent["yoga_session_#{counter}"] = {}
      most_recent["yoga_session_#{counter}"]["yoga_session_id"] = yoga_session[:id]
      most_recent["yoga_session_#{counter}"]["yoga_type"] = YogaType::ENUMS.key(yoga_session[:yoga_type])
      most_recent["yoga_session_#{counter}"]["first_name"] = teacher[:first_name]
      most_recent["yoga_session_#{counter}"]["last_name"] = teacher[:last_name]
      most_recent["yoga_session_#{counter}"]["date"] = sanitize_date_for_view(Date.parse(timestamp.in_time_zone(bt[:student_timezone]).to_s).to_s)
      most_recent["yoga_session_#{counter}"]["day_of_week"] = timestamp.in_time_zone(bt[:student_timezone]).strftime("%A")
      most_recent["yoga_session_#{counter}"]["time_range"] = "#{start_time} - #{end_time}"
      most_recent["yoga_session_#{counter}"]["duration"] = bt[:duration]
      most_recent["yoga_session_#{counter}"]["timezone"] = bt[:student_timezone]
      most_recent["yoga_session_#{counter}"]["timestamp"] = timestamp.in_time_zone(bt[:student_timezone])
      most_recent["yoga_session_#{counter}"]["refunded"] = yoga_session[:student_refund_given]
      counter += 1
    end
    return sorted = most_recent.sort_by{|k, v| v["timestamp"]}
  end

  def add_favorite_teacher
    if FavoriteTeacher.where(teacher_id: params[:id], student_id: Student.where(user_id: current_user).first.id).blank?
      favorite_teacher = FavoriteTeacher.new
      favorite_teacher[:teacher_id] = params[:id]
      favorite_teacher[:student_id] = Student.where(user_id: current_user).first.id
      if favorite_teacher.save!
        flash[:notice] = "Teacher has been saved to favorites!"
      else
        flash[:notice] = "Teacher was unable to be saved to favorites. Please try again."
      end
      return redirect_to request.referrer
    else
      flash[:notice] = "Teacher has already been added to your favorites."
      return redirect_to request.referrer
    end
  end

  def get_favorite_teachers
    teachers = []
    favorite_teachers = FavoriteTeacher.where(student_id: @student)
    favorite_teachers.each do |ft|
      teachers << Teacher.find(ft[:teacher_id])
    end
    return teachers
  end

  def destroy_favorite_teacher
    favorite_teacher = FavoriteTeacher.where(teacher_id: params[:id], student_id: Student.where(user_id: current_user).first.id).first
    if favorite_teacher.delete
      flash[:notice] = "Yoga Teacher deleted successfully!"
    else
      flash[:notice] = "Yoga Teacher DID NOT delete. Please try again."
    end
    return redirect_to request.referrer
  end

  def get_upcoming_yoga_sessions
    upcoming_yoga_sessions = {}
    next_booked_times = TeacherBookedTime.where("session_date >= ?", Date.today).where(student_id: @student).limit(15).order(session_date: :asc)
    if next_booked_times.empty?
      return "no-upcoming-sessions"
    else
      counter = 1
      next_booked_times.each do |bt|
        yoga_session = YogaSession.where(teacher_booked_time_id: bt).first
        next if yoga_session.nil?
        teacher = Teacher.find(yoga_session[:teacher_id])
        time_range = sanitize_date_range_for_view(bt[:time_range], bt[:student_timezone])
        split_date = bt[:session_date].to_s.split("-")
        Time.zone = bt[:teacher_timezone]
        split_time_range = time_range.split(" - ")
        start_time = sanitize_date_for_time_only(Time.parse(split_time_range[0]).in_time_zone(bt[:student_timezone]))
        end_time = sanitize_date_for_time_only((Time.parse(split_time_range[1]) - 1).in_time_zone(bt[:student_timezone]))
        timestamp_time = Time.parse(split_time_range[0]).in_time_zone(bt[:teacher_timezone])
        timestamp = Time.zone.local(split_date[0], split_date[1], split_date[2], timestamp_time.strftime("%k"), timestamp_time.strftime("%M"))
        upcoming_yoga_sessions["yoga_session_#{counter}"] = {}
        upcoming_yoga_sessions["yoga_session_#{counter}"]["yoga_session_id"] = yoga_session[:id]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["yoga_type"] = YogaType::ENUMS.key(yoga_session[:yoga_type])
        upcoming_yoga_sessions["yoga_session_#{counter}"]["first_name"] = teacher[:first_name]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["last_name"] = teacher[:last_name]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["date"] = sanitize_date_for_view(Date.parse(timestamp.in_time_zone(bt[:student_timezone]).to_s).to_s)
        upcoming_yoga_sessions["yoga_session_#{counter}"]["cancelled"] = yoga_session[:teacher_cancelled_session]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["day_of_week"] = timestamp.in_time_zone(bt[:student_timezone]).strftime("%A")
        upcoming_yoga_sessions["yoga_session_#{counter}"]["time_range"] = "#{start_time} - #{end_time}"
        upcoming_yoga_sessions["yoga_session_#{counter}"]["duration"] = bt[:duration]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["timezone"] = bt[:student_timezone]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["timestamp"] = timestamp.in_time_zone(bt[:student_timezone])
        upcoming_yoga_sessions["yoga_session_#{counter}"]["refunded"] = yoga_session[:student_refund_given]
        counter += 1
      end
      return sorted = upcoming_yoga_sessions.sort_by{|k, v| v["timestamp"]}
    end
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
