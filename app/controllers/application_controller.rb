class ApplicationController < ActionController::Base
  # http_basic_authenticate_with name: ENV["yogalit_auth_name"], password: ENV["yogalit_auth_password"]
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  after_action :not_blocked_or_blacklisted?
  require 'openssl'

  def split_start_time
    hour = []
    minute = []
    time_split = params[:start_time].split(":")
    hour << time_split[0]
    hour << time_split[1][2]
    hour << time_split[1][3]
    @start_hour = Time.strptime("#{hour.join}", "%I%P").strftime("%H").to_i
    minute << time_split[1][0]
    minute << time_split[1][1]
    @start_minute = minute.join("").to_i
  end

  def split_end_time
    hour = []
    minute = []
    time_split = params[:end_time].split(":")
    hour << time_split[0]
    hour << time_split[1][2]
    hour << time_split[1][3]
    @end_hour = Time.strptime("#{hour.join}", "%I%P").strftime("%H").to_i
    minute << time_split[1][0]
    minute << time_split[1][1]
    @end_minute = minute.join("").to_i
  end

  def split_date_and_time(bt)
    date_split = bt[:session_date].to_s.split("-")
    @year = date_split[0]
    @month = date_split[1]
    @day = date_split[2]

    start_time = Time.at(bt[:time_range].first).in_time_zone(bt[:teacher_timezone])
    @start_hour = start_time.strftime("%k")
    @start_minute = start_time.strftime("%M")

    end_time = Time.at(bt[:time_range].last).in_time_zone(bt[:teacher_timezone])
    @end_hour = end_time.strftime("%k")
    @end_minute = end_time.strftime("%M")
  end

  def not_blocked_or_blacklisted?
    if user_signed_in?
      if current_user[:teacher_or_student] == "teacher"
        teacher = Teacher.where(user_id: current_user).first
      end
      if current_user[:blacklisted]
        user = User.find(current_user[:id])
        sign_out user
        return false
      elsif !teacher.nil?
        if teacher[:blocked] || teacher[:blacklisted]
          user = User.find(current_user[:id])
          sign_out user
          return false
        end
      else
        return true
      end
    else
      return true
    end
  end

  def teacher_not_blocked?
    teacher = Teacher.where(user_id: current_user[:id]).first
    return teacher[:blocked] ? false : true
  end

  def teacher_not_blacklisted?
    teacher = Teacher.where(user_id: current_user[:id]).first
    return teacher[:blacklisted] ? false : true
  end

  def authenticate_admin
    if current_user[:teacher_or_student] == "admin" && ["chris@admin.com"].include?(current_user[:email])
      return true
    else
      return false
    end
  end

  def google_authorize_teacher
    if Rails.env.development?
      redirect_uri = "http://localhost:3000/new_teacher_interview"
    else
      redirect_uri = "http://yogalit.com/new_teacher_interview"
    end
    session[:google_calendar_access_token] = nil
    client = Signet::OAuth2::Client.new({
      client_id: ENV["google_calendar_client_id"],
      client_secret: ENV["google_calendar_client_secret"],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: "https://www.googleapis.com/auth/calendar",
      redirect_uri: redirect_uri
    })
    return redirect_to client.authorization_uri.to_s
  end

end
