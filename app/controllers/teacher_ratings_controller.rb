class TeacherRatingsController < ApplicationController
  before_action :authenticate_user!
  include ApplicationHelper

  def new
    student = Student.where(user_id: current_user[:id]).first
    booked_times = TeacherBookedTime.where(student_id: student, teacher_rating_given: false).where("session_date <= ?", Date.parse(Time.now.to_s))
    @unrated_sessions = booked_times.blank? ? nil : get_unrated_sessions_info(booked_times)
  end

  def create
    teacher_rating = TeacherRating.new
    teacher_rating[:yoga_session_id] = params[:id]
    ys = YogaSession.find(params[:id])
    teacher_rating[:teacher_id] = ys[:teacher_id]
    teacher_rating[:score] = params[:score]
    teacher_rating[:comment] = params[:comment]
    if teacher_rating.save!
      bt = TeacherBookedTime.find(ys[:teacher_booked_time_id])
      bt[:teacher_rating_given] = true
      begin
        bt.save!
      rescue e
        puts e
      end
      update_teacher_average_rating(ys[:teacher_id])
      flash[:notice] = "Your rating has been submitted!"
      path = students_path
    else
      flash[:notice] = "Your rating did not submit. Please try again"
      path = request.referrer
    end
    return redirect_to path
  end

  def update_teacher_average_rating(teacher_id)
    teacher = Teacher.find(teacher_id)
    teacher_ratings = TeacherRating.where(teacher_id: teacher_id)
    scores = []
    teacher_ratings.each {|tr| scores << tr[:score]}
    scores.sort!
    average = (scores.inject {|sum, el| sum + el}.to_f / scores.size).round(2)
    teacher[:average_rating] = average
    begin
      teacher.save!
    rescue e
      puts e
    end
  end

  def get_unrated_sessions_info(booked_times)
    unrated = {}
    counter = 1
    booked_times.each do |bt|
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
      unrated["yoga_session_#{counter}"] = {}
      unrated["yoga_session_#{counter}"]["yoga_session_id"] = yoga_session[:id]
      unrated["yoga_session_#{counter}"]["yoga_type"] = YogaType::ENUMS.key(yoga_session[:yoga_type])
      unrated["yoga_session_#{counter}"]["first_name"] = teacher[:first_name]
      unrated["yoga_session_#{counter}"]["last_name"] = teacher[:last_name]
      unrated["yoga_session_#{counter}"]["date"] = sanitize_date_for_view(Date.parse(timestamp.in_time_zone(bt[:student_timezone]).to_s).to_s)
      unrated["yoga_session_#{counter}"]["day_of_week"] = timestamp.in_time_zone(bt[:student_timezone]).strftime("%A")
      unrated["yoga_session_#{counter}"]["time_range"] = "#{start_time} - #{end_time}"
      unrated["yoga_session_#{counter}"]["duration"] = bt[:duration]
      unrated["yoga_session_#{counter}"]["timezone"] = bt[:student_timezone]
      unrated["yoga_session_#{counter}"]["timestamp"] = timestamp.in_time_zone(bt[:student_timezone])
      unrated["yoga_session_#{counter}"]["refunded"] = yoga_session[:student_refund_given]
      counter += 1
    end
    return sorted = unrated.sort_by{|k, v| v["timestamp"]}
  end

end
