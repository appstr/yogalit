class YogalitAdminsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin
  include ApplicationHelper

  def index
  end

  def reported_non_refund_requested_yoga_sessions
    yoga_sessions = YogaSession.where(video_under_review: true, student_requested_refund: false)
    build_reported_sessions_hash(yoga_sessions)
  end

  def reported_refund_requested_yoga_sessions
    yoga_sessions = YogaSession.where(video_under_review: true, student_requested_refund: true)
    build_reported_sessions_hash(yoga_sessions)
  end

  def build_reported_sessions_hash(yoga_sessions)
    @reported_sessions = {}
    counter = 1
    if yoga_sessions.empty?
      @reported_sessions = "no_data"
    else
      yoga_sessions.each do |ys|
        student = Student.find(ys[:student_id])
        student_email = User.find(student[:user_id]).email
        teacher = Teacher.find(ys[:teacher_id])
        teacher_email = User.find(teacher[:user_id]).email
        reported_session = ReportedYogaSession.where(yoga_session_id: ys[:id]).first
        booked_time = TeacherBookedTime.find(ys[:teacher_booked_time_id])
        @reported_sessions["reported_session_#{counter}"] = {}
        @reported_sessions["reported_session_#{counter}"]["yoga_session_id"] = ys[:id]
        @reported_sessions["reported_session_#{counter}"]["teacher_name"] = "#{teacher[:first_name].capitalize} #{teacher[:last_name].capitalize}"
        @reported_sessions["reported_session_#{counter}"]["teacher_email"] = teacher_email
        @reported_sessions["reported_session_#{counter}"]["student_name"] = "#{student[:first_name].capitalize} #{student[:last_name].capitalize}"
        @reported_sessions["reported_session_#{counter}"]["student_email"] = student_email
        @reported_sessions["reported_session_#{counter}"]["teacher_time_range"] = "#{sanitize_date_for_time_only(Time.at(booked_time[:time_range].first).in_time_zone(booked_time[:teacher_timezone]))} - #{sanitize_date_for_time_only(Time.at(booked_time[:time_range].last).in_time_zone(booked_time[:teacher_timezone]))}"
        @reported_sessions["reported_session_#{counter}"]["teacher_timezone"] = booked_time[:teacher_timezone]
        @reported_sessions["reported_session_#{counter}"]["student_timezone"] = booked_time[:student_timezone]
        @reported_sessions["reported_session_#{counter}"]["yoga_type"] = YogaType::ENUMS.key(ys[:yoga_type])
        @reported_sessions["reported_session_#{counter}"]["duration"] = booked_time[:duration]
        @reported_sessions["reported_session_#{counter}"]["reported_session_description"] = reported_session[:description]
        @reported_sessions["reported_session_#{counter}"]["opentok_session_id"] = ys[:opentok_session_id]
        counter += 1
      end
    end
  end


end
