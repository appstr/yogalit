class YogaSessionsController < ApplicationController
  before_action :authenticate_user!
  require "opentok"

  def live_yoga_session
    if current_user[:teacher_or_student] == "teacher"
      teacher = Teacher.where(user_id: current_user).first
      yoga_session = YogaSession.where(teacher_id: teacher, id: params[:id]).first
      booked_time = TeacherBookedTime.find(yoga_session[:teacher_booked_time_id])
    elsif current_user[:teacher_or_student] == "student"
      student = Student.where(user_id: current_user).first
      yoga_session = YogaSession.where(student_id: student, id: params[:id]).first
      booked_time = TeacherBookedTime.find(yoga_session[:teacher_booked_time_id])
    end
    if !allow_yoga_session?(booked_time)
      flash[:notice] = "The Yoga Session is not ready to be joined yet. Sessions open 5 minutes before the scheduled start-time."
      return redirect_to request.referrer
    end
    data = {"yoga_session_id" => yoga_session[:id]}.to_json
    @opentok_session_id = yoga_session[:opentok_session_id]
    opentok = OpenTok::OpenTok.new ENV["opentok_api_key"], ENV["opentok_api_secret"]
    Time.zone = booked_time[:teacher_timezone]
    @opentokToken = opentok.generate_token(@opentok_session_id, {
        :role        => :publisher,
        :expire_time => Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00).to_i,
        :data        => data
      })
  end

  private

  def allow_yoga_session?(booked_time)
    Time.zone = booked_time[:teacher_timezone]
    get_date_and_time_separated(booked_time)
    if Time.now.in_time_zone(booked_time[:teacher_timezone]) >= (Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00) - 300)
      return true
    else
      return false
    end
  end

  def get_date_and_time_separated(booked_time)
    date = booked_time[:session_date]
    @year = date.strftime("%Y").to_i
    @month = date.strftime("%m").to_i
    @day = date.strftime("%d").to_i

    start_time = Time.at(booked_time[:time_range].first).in_time_zone(booked_time[:teacher_timezone])
    @start_hour = start_time.strftime("%k").to_i
    @start_minute = start_time.strftime("%M").to_i

    end_time = Time.at(booked_time[:time_range].last + 59).in_time_zone(booked_time[:teacher_timezone])
    @end_hour = end_time.strftime("%k").to_i
    @end_minute = end_time.strftime("%M").to_i
  end

end
