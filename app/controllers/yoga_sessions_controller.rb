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
      flash[:notice] = "The Yoga Session is not ready to be joined yet or has already ended."
      if current_user[:teacher_or_student] == "teacher"
        return redirect_to teachers_path(section: "yoga_sessions")
      else
        return redirect_to root_path
      end
    end
    data = {"yoga_session_id" => yoga_session[:id]}.to_json
    @opentok_session_id = yoga_session[:opentok_session_id]
    opentok = OpenTok::OpenTok.new ENV["opentok_api_key"], ENV["opentok_api_secret"]
    Time.zone = booked_time[:teacher_timezone]
    convert_end_time_to_gmt(booked_time[:teacher_timezone])
    @opentokToken = opentok.generate_token(@opentok_session_id, {
        :role        => :publisher,
        :expire_time => Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00).to_i,
        :data        => data
      })
  end

  def report_a_yoga_session_problem
    yoga_session = YogaSession.find(params[:id])
    if yoga_session[:video_under_review] || yoga_session[:video_reviewed]
      flash[:notice] = "This video has already had a report filed."
      return redirect_to request.referrer
    end
    @teacher = Teacher.find(yoga_session[:teacher_id])
    @student = Student.find(yoga_session[:student_id])
    @booked_time = TeacherBookedTime.find(yoga_session[:teacher_booked_time_id])
    @yoga_type = YogaType::ENUMS.key(yoga_session[:yoga_type])
  end

  def submit_yoga_session_problem
    if current_user[:teacher_or_student] == "student"
      reported_yoga_session = StudentReportedYogaSession.new
      student = Student.where(user_id: current_user[:id]).first
      yoga_session = YogaSession.where(id: params[:id], student_id: student).first
    else
      reported_yoga_session = TeacherReportedYogaSession.new
      teacher = Teacher.where(user_id: current_user[:id]).first
      yoga_session = YogaSession.where(id: params[:id], teacher_id: teacher).first
    end
    yoga_session[:video_under_review] = true
    yoga_session[:student_requested_refund] = true if params[:requesting_refund]
    if yoga_session.save!
      reported_yoga_session[:teacher_id] = yoga_session[:teacher_id]
      reported_yoga_session[:student_id] = yoga_session[:student_id]
      reported_yoga_session[:yoga_session_id] = yoga_session[:id]
      reported_yoga_session[:description] = params[:description]
      begin
        reported_yoga_session.save!
      rescue e
        puts e
      end
      flash[:notice] = "Your report was made and a Yogalit administrator will contact your email with any further questions or information."
    else
      flash[:notice] = "Your report was not made. Please try again or contact Yogalit through the Contact link in the header."
    end
    return redirect_to root_path
  end

  def convert_end_time_to_gmt(teacher_timezone)
    Time.zone = teacher_timezone
    @gmt_end_time = Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00).in_time_zone("GMT").to_s
  end

  private

  def allow_yoga_session?(booked_time)
    Time.zone = booked_time[:teacher_timezone]
    get_date_and_time_separated(booked_time)
    if Time.now.in_time_zone(booked_time[:teacher_timezone]) >= (Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00) - 300) && Time.now.in_time_zone(booked_time[:teacher_timezone]) < Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00)
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
