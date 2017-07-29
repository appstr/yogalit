class TeachersController < ApplicationController
  before_action :authenticate_user!, except: [:teacher_profile]
  skip_before_action :verify_authenticity_token, only: [:toggle_vacation_mode]
  include ApplicationHelper
  require 'signet/oauth_2/client'

  def index
    @teacher = Teacher.where(user_id: current_user).first
    # Returns an array of type_ids associated to the Teacher --> @type_ids
    get_teacher_yoga_types
    # Teacher Images
    @teacher_image = TeacherImage.new
    @teacher_photos = TeacherImage.where(teacher_id: @teacher)
    # Teacher Videos
    @teacher_video = TeacherVideo.new
    @teacher_videos = TeacherVideo.where(teacher_id: @teacher)

    @teacher_price_range_form = TeacherPriceRange.new
    @teacher_price_ranges = TeacherPriceRange.where(teacher_id: @teacher).first
    @upcoming_yoga_sessions = get_upcoming_yoga_sessions
    @upcoming_yoga_sessions_count = @upcoming_yoga_sessions.length if !@upcoming_yoga_sessions.blank?
    @most_recent_yoga_sessions = get_most_recent_yoga_sessions
    @favorited_count = FavoriteTeacher.where(teacher_id: @teacher[:id]).count
    # Teacher H.O.O
    @teacher_monday_time_frame = TeacherMondayTimeFrame.new
    @teacher_monday_time_frames = TeacherMondayTimeFrame.where(teacher_id: @teacher)
    @teacher_tuesday_time_frame = TeacherTuesdayTimeFrame.new
    @teacher_tuesday_time_frames = TeacherTuesdayTimeFrame.where(teacher_id: @teacher)
    @teacher_wednesday_time_frame = TeacherWednesdayTimeFrame.new
    @teacher_wednesday_time_frames = TeacherWednesdayTimeFrame.where(teacher_id: @teacher)
    @teacher_thursday_time_frame = TeacherThursdayTimeFrame.new
    @teacher_thursday_time_frames = TeacherThursdayTimeFrame.where(teacher_id: @teacher)
    @teacher_friday_time_frame = TeacherFridayTimeFrame.new
    @teacher_friday_time_frames = TeacherFridayTimeFrame.where(teacher_id: @teacher)
    @teacher_saturday_time_frame = TeacherSaturdayTimeFrame.new
    @teacher_saturday_time_frames = TeacherSaturdayTimeFrame.where(teacher_id: @teacher)
    @teacher_sunday_time_frame = TeacherSundayTimeFrame.new
    @teacher_sunday_time_frames = TeacherSundayTimeFrame.where(teacher_id: @teacher)
    # Teacher Holidays
    @teacher_holiday = TeacherHoliday.new
    @teacher_holidays = TeacherHoliday.where(teacher_id: @teacher[:id])
    # Searchables
    @yoga_type_chosen = YogaType.where(teacher_id: @teacher).first
    @teacher_prices_chosen = TeacherPriceRange.where(teacher_id: @teacher).first
    if !@teacher_monday_time_frames.blank?
      @date_chosen = true
    elsif !@teacher_tuesday_time_frames.blank?
      @date_chosen = true
    elsif !@teacher_wednesday_time_frames.blank?
      @date_chosen = true
    elsif !@teacher_thursday_time_frames.blank?
      @date_chosen = true
    elsif !@teacher_friday_time_frames.blank?
      @date_chosen = true
    elsif !@teacher_saturday_time_frames.blank?
      @date_chosen = true
    elsif !@teacher_sunday_time_frames.blank?
      @date_chosen = true
    else
      @date_chosen = false
    end
  end

  def get_most_recent_yoga_sessions
    recent_booked_times = []
    booked_times = TeacherBookedTime.where(teacher_id: @teacher).where("session_date >= ? AND session_date <= ?", Date.today - 2, Date.today + 2)
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
      student = Student.find(yoga_session[:student_id])
      date = sanitize_date_for_view(bt[:session_date].to_s)
      day_of_week = bt[:session_date].strftime("%A")
      time_range = sanitize_date_range_for_view(bt[:time_range], bt[:teacher_timezone])
      split_date = bt[:session_date].to_s.split("-")
      Time.zone = bt[:teacher_timezone]
      split_time_range = time_range.split(" - ")
      start_time = sanitize_date_for_time_only(Time.parse(split_time_range[0]).in_time_zone(bt[:teacher_timezone]))
      end_time = sanitize_date_for_time_only((Time.parse(split_time_range[1]) - 1).in_time_zone(bt[:teacher_timezone]))
      timestamp_time = Time.parse(split_time_range[0]).in_time_zone(bt[:teacher_timezone])
      timestamp = Time.zone.local(split_date[0], split_date[1], split_date[2], timestamp_time.strftime("%k"), timestamp_time.strftime("%M"))
      most_recent["yoga_session_#{counter}"] = {}
      most_recent["yoga_session_#{counter}"]["yoga_session_id"] = yoga_session[:id]
      most_recent["yoga_session_#{counter}"]["yoga_type"] = YogaType::ENUMS.key(yoga_session[:yoga_type])
      most_recent["yoga_session_#{counter}"]["first_name"] = student[:first_name]
      most_recent["yoga_session_#{counter}"]["last_name"] = student[:last_name]
      most_recent["yoga_session_#{counter}"]["date"] = date
      most_recent["yoga_session_#{counter}"]["day_of_week"] = day_of_week
      most_recent["yoga_session_#{counter}"]["time_range"] = "#{start_time} - #{end_time}"
      most_recent["yoga_session_#{counter}"]["duration"] = bt[:duration]
      most_recent["yoga_session_#{counter}"]["timezone"] = bt[:teacher_timezone]
      most_recent["yoga_session_#{counter}"]["timestamp"] = timestamp
      most_recent["yoga_session_#{counter}"]["refunded"] = yoga_session[:student_refund_given]
      counter += 1
    end
    return sorted = most_recent.sort_by{|k, v| v["timestamp"]}
  end

  def add_bio_to_teacher_table
    teacher = Teacher.where(user_id: current_user).first
    teacher[:bio] = params[:my_biography]
    begin
      teacher.save!
      flash[:notice] = "Your bio was saved successfully!"
    rescue e
      puts "RAILS_ERROR: #{e}"
      flash[:notice] = 'Your bio was not saved, please try again.'
    end
    return redirect_to request.referrer
  end

  def new
    if Teacher.teacher_exists?(current_user)
      teacher = Teacher.where(user_id: current_user).first
      if teacher[:is_verified]
        return redirect_to teachers_path
      elsif InterviewBookedTime.where(teacher_id: teacher).first.nil?
        return google_authorize_teacher
      else
        return redirect_to new_teacher_interview_path
      end
    end
    @teacher = Teacher.new
  end

  def create
    if Teacher.teacher_exists?(current_user)
      teacher = Teacher.where(user_id: current_user).first
      if teacher[:is_verified]
        return redirect_to teachers_path
      elsif InterviewBookedTime.where(teacher_id: teacher).first.nil?
        return google_authorize_teacher
      else
        return redirect_to new_teacher_interview_path
      end
    end
    params[:teacher][:first_name].downcase!
    params[:teacher][:last_name].downcase!
    @teacher = Teacher.new(teacher_params)
    @teacher[:user_id] = current_user[:id]
    @teacher[:average_rating] = 0
    if @teacher.valid? && @teacher.save
      return google_authorize_teacher
    else
      error_message = ""
      @teacher.errors.full_messages.each {|err| error_message << "#{err} "}
      flash[:notice] = error_message
      render("new")
    end
  end

  def edit
    @teacher = Teacher.find(params[:id])
  end

  def update
    @teacher = Teacher.find(params[:id])
    @teacher[:first_name] = params[:teacher][:first_name].downcase
    @teacher[:last_name] = params[:teacher][:last_name].downcase
    @teacher[:phone] = params[:teacher][:phone]
    @teacher[:timezone] = params[:teacher][:timezone]
    @teacher[:bio] = params[:teacher][:bio]
    @teacher.profile_pic = params[:teacher][:profile_pic] if !params[:teacher][:profile_pic].nil?
    @teacher.certificate = params[:teacher][:certificate] if !params[:teacher][:certificate].nil?
    if @teacher.save
      flash[:notice] = "Your profile info was updated successfully!"
      return redirect_to teachers_path
    else
      flash[:notice] = "Your profile info was not updated."
      render("edit")
    end
  end

  def show
    if params[:from_teacher_profile]
      build_params_from_teacher_profile
      not_on_holiday_ids = YogaTeacherSearchesController.new.yoga_teachers_not_on_holiday([params[:id]], Time.parse(params[:session_date]))
      if not_on_holiday_ids.empty?
        flash[:notice] = "Teacher is on Holiday for this date."
        return redirect_to request.referrer
      end
      available_on_day_of_week = YogaTeacherSearchesController.new.yoga_teachers_available_on(params[:day_of_week], not_on_holiday_ids, params[:session_date], params[:student_timezone], params[:time_frame] )
      if available_on_day_of_week.empty?
        flash[:notice] = "Teacher is unavailable. Please choose another date or time."
        return redirect_to request.referrer
      end
    end
    @teacher = Teacher.find(params[:id])
    @teacher_price_ranges = TeacherPriceRange.where(teacher_id: @teacher).first
    # duration = get_duration_in_seconds
    # teacher_time_frames = get_teacher_time_frames_for(params[:day_of_week])
    # available_booking_times = build_teacher_time_frame(teacher_time_frames, duration)
    # extra_booking_times = get_teacher_extra_time_frames_for(params[:day_of_week], duration)
    # available_booking_times = merge_booking_times(available_booking_times, extra_booking_times) if !extra_booking_times.nil?
    # filtered_booking_times = get_res_filtered_booking_times(available_booking_times, duration)
    # @filtered_booking_time_options = format_filtered_booking_times(filtered_booking_times)
    @favorite_teacher_count = FavoriteTeacher.where(teacher_id: @teacher).count
    @teacher_images = TeacherImage.where(teacher_id: @teacher)
    @teacher_videos = TeacherVideo.where(teacher_id: @teacher)
    if params[:student_time_frame].nil?
      Time.zone = params[:student_timezone]
      split_time = params[:time_frame].split(" - ")
      date = Time.parse(params[:session_date])
      start_t = Time.parse(split_time.first, date)
      end_t = Time.parse(split_time.last, date)
      split_student_time_frame = [Time.zone.local(start_t.strftime("%Y"), start_t.strftime("%m"), start_t.strftime("%d"), start_t.strftime("%k"), start_t.strftime("%M")), Time.zone.local(end_t.strftime("%Y"), end_t.strftime("%m"), end_t.strftime("%d"), end_t.strftime("%k"), end_t.strftime("%M"))]
      @student_time_frame = split_student_time_frame.first..split_student_time_frame.last
    else
      split_student_time_frame = params[:student_time_frame].split("..")
      @student_time_frame = Time.parse(split_student_time_frame.first)..Time.parse(split_student_time_frame.last)
    end
  end

  def teacher_profile
    @teacher = Teacher.find(params[:id])
    @teacher_available_yoga_types = get_teacher_available_yoga_types
    @favorite_teacher_count = FavoriteTeacher.where(teacher_id: @teacher).count
    @teacher_photos = TeacherImage.where(teacher_id: @teacher)
    @teacher_videos = TeacherVideo.where(teacher_id: @teacher)
    @teacher_holidays = TeacherHoliday.where(teacher_id: @teacher)
    @teacher_monday_time_frame = TeacherMondayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
    @teacher_tuesday_time_frame = TeacherTuesdayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
    @teacher_wednesday_time_frame = TeacherWednesdayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
    @teacher_thursday_time_frame = TeacherThursdayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
    @teacher_friday_time_frame = TeacherFridayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
    @teacher_saturday_time_frame = TeacherSaturdayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
    @teacher_sunday_time_frame = TeacherSundayTimeFrame.where(teacher_id: @teacher).first.nil? ? "Closed" : "Open"
  end

  def toggle_vacation_mode
    teacher = Teacher.where(user_id: current_user).first
    teacher[:vacation_mode] = teacher[:vacation_mode] ? false : true
    if teacher[:vacation_mode]
      teacher[:is_searchable] = false
    else
      teacher[:is_searchable] = Teacher.qualifies_for_search?(current_user)
    end
    if teacher.save!
      flash[:notice] = teacher[:vacation_mode] ? "Vacation Mode: ON" : "Vacation Mode: OFF"
    else
      flash[:notice] = "Your account could not be updated. Please try again or contact Yogalit directly."
    end
    return render json: {searchable: teacher[:is_searchable], verified: teacher[:is_verified], vacation_mode: teacher[:vacation_mode]}
  end

  def new_teacher_interview
    if Teacher.teacher_exists?(current_user)
      teacher = Teacher.where(user_id: current_user).first
      return redirect_to teachers_path if teacher[:is_verified]
    end
    @teacher = Teacher.where(user_id: current_user).first
    if Rails.env.development?
      redirect_uri = "http://localhost:3000/new_teacher_interview"
    else
      redirect_uri = "http://yogalit.com/new_teacher_interview"
    end
    if session[:google_calendar_access_token].nil?
      client = Signet::OAuth2::Client.new({
        client_id: ENV["google_calendar_client_id"],
        client_secret: ENV["google_calendar_client_secret"],
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        redirect_uri: redirect_uri,
        code: request.query_parameters["code"]
      })
      data = client.fetch_access_token!
      session[:google_calendar_access_token] = data["access_token"]
    end
    @available_times = get_available_interview_times(params[:session_date])
    if params[:new_date_request]
      return render json: {success: true, available_times: @available_times}
    end
  end

  def get_available_interview_times(session_date)
    if session_date.nil?
      @session_date = Time.now.in_time_zone(@teacher[:timezone])
    else
      split_date(Date.parse(params[:session_date]))
      Time.zone = @teacher[:timezone]
      @session_date = Time.zone.local(@year, @month, @day, 00, 00, 00)
    end
    taken_start_times = get_taken_start_times_on(@session_date)
    all_times = create_all_times_obj(@session_date)
    @filtered_available_times = filter_available_interview_times(all_times, taken_start_times)
  end

  def filter_available_interview_times(all_times, taken_start_times)
    filtered_times = []
    # Iterate through all_times (array of arrays) --> [["9:30-10:00", 2017-05-10:9:00:00..2017-05-10:10:00:00]]
    # Check if taken_start_times (array) --> [2017-05-10:9:00:00, 2017-05-10:10:30:00, 2017-05-10:14:30:00]
    if taken_start_times.blank?
      filtered_times = all_times
    else
      all_times.each do |at|
        filtered_times << at if !taken_start_times.include?(at[1].first)
      end
    end
    if Date.parse(@session_date.to_s) == Date.parse(Time.now.in_time_zone(@teacher[:timezone]).to_s)
      filtered_times = remove_times_before_now_for_interview(filtered_times)
    end
    return filtered_times
  end

  def remove_times_before_now_for_interview(filtered_times)
    new_times = []
    if !filtered_times.blank?
      filtered_times.each do |ft|
        new_times << ft if ft[1].first > (Time.now.in_time_zone(@teacher[:timezone]) + 3600)
      end
    end
    return new_times
  end

  def get_taken_start_times_on(session_date)
    start_times = []
    taken_times = InterviewBookedTime.where("interview_date = ?", Date.parse(session_date.to_s))
    if !taken_times.blank?
      taken_times.each do |tt|
        start_times << Time.at(tt[:time_range].first).in_time_zone(@teacher[:timezone])
      end
    end
    return start_times
  end

  def create_all_times_obj(session_date)
    # return all times for the @session_date given, regardless if Date.today.
    all_times = []
    Time.zone = @teacher[:timezone]
    split_date(session_date)
    start_time = Time.zone.local(@year, @month, @day, 00, 00, 00)
    while(Date.parse(session_date.to_s) == Date.parse(start_time.to_s)) do
      all_times << ["#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + 1800)}",
                    (start_time..(start_time + 1800))
                   ]
      start_time = start_time + 1800
    end
    return all_times
  end

  def split_date(session_date)
    @year = session_date.strftime("%Y").to_i
    @month = session_date.strftime("%m").to_i
    @day = session_date.strftime("%d").to_i
  end

  def confirm_teacher_interview
    if params[:date].nil?
      flash[:notice] = "Date cannot be blank."
      return redirect_to request.referrer
    end
    teacher = Teacher.where(user_id: current_user).first
    interview = InterviewBookedTime.where(teacher_id: teacher[:id]).first
    if interview.nil?
      interview = InterviewBookedTime.new
    else
      flash[:notice] = "An interview was already created."
      return redirect_to teachers_path
    end
    interview[:teacher_id] = teacher[:id]
    interview[:interview_date] = Date.parse(params[:date])
    split_time_range = params[:time_range_select].split("..")
    interview[:time_range] = (Time.parse(split_time_range[0])..Time.parse(split_time_range[1]))
    interview[:teacher_timezone] = teacher[:timezone]
    interview[:teacher_cancelled] = false
    interview[:completed] = false
    if interview.save!
      request = Typhoeus::Request.new(
        "https://www.googleapis.com/calendar/v3/calendars/calendarId/events",
        method: :post,
        body: {
                start: {
                  dateTime: Time.parse(split_time_range[0])
                },
                end: {
                  dateTime: Time.parse(split_time_range[1])
                },
                attendees: [
                  {
                    email: "#{ENV["yogalit_interview_email"]}"
                  }
                ],
                summary: "Yogalit Interview"
              }.to_json,
        params: { access_token: session[:google_calendar_access_token], calendarId: "primary", sendNotifications: true },
        headers: {"Content-Type": "application/json"}
      )
      response = request.run
      if response.success?
        teacher_email = User.find(teacher[:user_id]).email
        UserMailer.new_teacher_interview_email(teacher_email).deliver_now
        flash[:notice] = "A Calendar Event was created successfully!"
        return redirect_to teachers_path
      else
        flash[:notice] = "An error occurred while trying to book the Calendar Event. Please try again."
        return google_authorize_teacher
      end
    end
    flash[:notice] = "An error occurred while trying to book the Calendar Event. Please try again."
    return redirect_to request.referrer
  end

  def get_teacher_available_yoga_types
    available_types = []
    yoga_types = YogaType.where(teacher_id: @teacher)
    yoga_types.each do |yt|
      available_types << [YogaType::ENUMS.key(yt[:type_id]), yt[:type_id]]
    end
    return available_types
  end

  def emergency_cancel
    yoga_session = YogaSession.find(params[:id])
    if yoga_session[:teacher_cancelled_session] || yoga_session[:student_refund_given]
      flash[:notice] = "Session has already been cancelled."
      return redirect_to request.referrer
    end
    bt = TeacherBookedTime.find(yoga_session[:teacher_booked_time_id])
    date = Time.parse(bt[:session_date].to_s)
    Time.zone = bt[:teacher_timezone]
    if Time.zone.local(date.strftime("%Y"), date.strftime("%m"), date.strftime("%d"), bt[:time_range].first.in_time_zone(bt[:teacher_timezone]).strftime("%k"), bt[:time_range].first.in_time_zone(bt[:teacher_timezone]).strftime("%M")) <= Time.now.in_time_zone(bt[:teacher_timezone])
      flash[:notice] = "Sessions cannot be cancelled once they have started."
      return redirect_to request.referrer
    end
    teacher = Teacher.where(user_id: current_user).first
    teacher_cancelled_count = TeacherEmergencyCancel.where(teacher_id: teacher).count
    if teacher_cancelled_count == 3
      flash[:notice] = "You have reached the maximum number of cancellations allowed."
    else
      yoga_session[:teacher_cancelled_session] = true
      yoga_session[:student_refund_given] = true
      teacher_emergency_cancel = TeacherEmergencyCancel.new
      teacher_emergency_cancel[:teacher_id] = teacher[:id]
      transaction_id = Payment.find(yoga_session[:payment_id]).transaction_id
      remaining = 3 - (teacher_cancelled_count + 1)
      if teacher_emergency_cancel.save! && yoga_session.save! && Payment.refund_successful?(transaction_id)
        student = Student.find(yoga_session[:student_id])
        student_email = User.find(student[:user_id]).email
        UserMailer.student_refund_email(student_email).deliver_now
        flash[:notice] = "Your cancellation has been submitted, you have #{remaining} cancellations remaining."
      else
        flash[:notice] = "Something went wrong, please try again or contact Yogalit directly."
      end
    end
    return redirect_to request.referrer
  end

  def build_params_from_teacher_profile
    params[:day_of_week] = Date.parse(params[:session_date]).strftime("%A")
    params[:student_timezone] = params[:student_timezone].first
    params[:session_date] = Date.parse(params[:session_date]).to_time.to_s
    params[:yoga_type] = YogaType::ENUMS.key(params[:yoga_type].to_i)
  end

  def merge_booking_times(available_booking_times, extra_booking_times)
    return available_booking_times.merge(extra_booking_times)
  end

  def get_duration_in_seconds
    if params[:duration] == "30"
      duration = 1800
    elsif params[:duration] == "60"
      duration = 3600
    elsif params[:duration] == "90"
      duration = 5400
    end
    return duration
  end

  def get_res_filtered_booking_times(available_booking_times, duration)
    booking_date = Date.parse(params[:session_date]).to_s.split("-")
    teacher_booked_times = TeacherBookedTime.where(teacher_id: @teacher).where('session_date = ?', Date.parse(Time.new(booking_date[0], booking_date[1], booking_date[2]).to_s))
    return remove_booked_times_from(available_booking_times, teacher_booked_times)
  end

  def remove_booked_times_from(available_booking_times, teacher_booked_times)
    filtered_times = available_booking_times
    available_booking_times.each do |av_bt|
      available_start = av_bt[1].first
      available_end = av_bt[1].last
      teacher_booked_times.each do |t_bt|
        booked_start = Time.at(t_bt[:time_range].first).in_time_zone(params[:student_timezone])
        booked_end = Time.at(t_bt[:time_range].last - 1).in_time_zone(params[:student_timezone]) - 59
        if ((booked_start).between?(available_start, available_end)) || ((booked_end).between?(available_start, available_end))
          if booked_start != available_end && available_start != booked_end
            if !filtered_times[("#{sanitize_date_for_time_only(available_start)} - #{sanitize_date_for_time_only(available_end)}")].nil?
              filtered_times.delete(("#{sanitize_date_for_time_only(available_start)} - #{sanitize_date_for_time_only(available_end)}"))
            end
            next
          end
        elsif ((available_start).between?(booked_start, booked_end)) || ((available_end).between?(booked_start, booked_end))
          if booked_start != available_end && available_start != booked_end
            if !filtered_times[("#{sanitize_date_for_time_only(available_start)} - #{sanitize_date_for_time_only(available_end)}")].nil?
              filtered_times.delete(("#{sanitize_date_for_time_only(available_start)} - #{sanitize_date_for_time_only(available_end)}"))
            end
            next
          end
        end
      end
    end
    return filtered_times
  end

  def format_filtered_booking_times(filtered_booking_times)
    formatted_times = []
    filtered_booking_times.each do |obj|
      formatted_times << [obj[0], obj[1]]
    end
    sorted_formatted_times = formatted_times.sort_by do |a,b|
      b.first.strftime("%k%M").to_i
    end
    sorted_formatted_times = remove_times_before_now(sorted_formatted_times)
    return sorted_formatted_times
  end

  def remove_times_before_now(sorted_formatted_times)
    new_times = []
    new_times_true = false
    sorted_formatted_times.each do |obj|
      if Date.parse(params["session_date"]) == Date.today && Time.now.in_time_zone(params[:student_timezone]) >= Time.parse(params[:session_date]).in_time_zone(params[:student_timezone])
        new_times_true = true
        if !(obj[1].first.strftime("%k%M").to_i <= Time.now.in_time_zone(params[:student_timezone]).strftime("%k%M").to_i + 60) && @start_time.day == obj[1].first.day
          new_times << [obj[0], obj[1]]
        end
      elsif Date.parse(params[:session_date]).wday == obj[1].first.wday
        new_times_true = true
        new_times << [obj[0], obj[1]]
      end
    end
    return new_times if new_times_true
    return sorted_formatted_times
  end

  def build_teacher_time_frame(teacher_time_frames, added_time)
    available_times = {}
    counter = 1
    Time.zone = params[:student_timezone]
    teacher_time_frames.each do |tf|
      if counter == 1
        @start_time = (Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone]))
        counter += 1
      end
      start_time = (Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone]))
      end_time = Time.at(tf[:time_range].last).in_time_zone(params[:student_timezone])
      while (start_time + added_time <= end_time) do
        if available_times.empty?
          available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                          (Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone])..(Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone]) + added_time))
          start_time = (Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone]) + 1800)
        elsif (start_time + added_time <= end_time)
          available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                          (Time.at(start_time).in_time_zone(params[:student_timezone])..(Time.at(start_time).in_time_zone(params[:student_timezone]) + added_time))
          start_time = (start_time + 1800)
        end
      end
    end
    return available_times
  end

  def get_teacher_time_frames_for(day_of_week)
    if day_of_week == "Monday"
      time_frames = TeacherMondayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Tuesday"
      time_frames = TeacherTuesdayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Wednesday"
      time_frames = TeacherWednesdayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Thursday"
      time_frames = TeacherThursdayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Friday"
      time_frames = TeacherFridayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Saturday"
      time_frames = TeacherSaturdayTimeFrame.where(teacher_id: @teacher[:id])
    else
      time_frames = TeacherSundayTimeFrame.where(teacher_id: @teacher[:id])
    end
    return time_frames
  end

  def get_teacher_extra_time_frames_for(day_of_week, duration)
    if day_of_week == "Monday"
        after_time_frames = TeacherTuesdayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherSundayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Tuesday"
        after_time_frames = TeacherWednesdayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherMondayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Wednesday"
        after_time_frames = TeacherThursdayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherTuesdayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Thursday"
        after_time_frames = TeacherFridayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherWednesdayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Friday"
        after_time_frames = TeacherSaturdayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherThursdayTimeFrame.where(teacher_id: @teacher[:id])
    elsif day_of_week == "Saturday"
        after_time_frames = TeacherSundayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherFridayTimeFrame.where(teacher_id: @teacher[:id])
    else
        after_time_frames = TeacherMondayTimeFrame.where(teacher_id: @teacher[:id])
        before_time_frames = TeacherSaturdayTimeFrame.where(teacher_id: @teacher[:id])
    end
    return nil if (before_time_frames.empty? && after_time_frames.empty?)
    return build_extra_relevant(before_time_frames, after_time_frames, duration)
  end

  def build_extra_relevant(before_time_frames, after_time_frames, added_time)
    available_times = {}
    if !before_time_frames.empty?
      before_time_frames.each do |tf|
        teacher_start_day = Time.at(tf[:time_range].first).in_time_zone(params[:teacher_timezone]).day
        teacher_last_day_in_student_tz = Time.at(tf[:time_range].last).in_time_zone(params[:student_timezone]).day
        if teacher_start_day < teacher_last_day_in_student_tz
          start_time = Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone])
          end_time = Time.at(tf[:time_range].last).in_time_zone(params[:student_timezone])
          end_time += 59 if end_time.strftime("%M").to_i == 59
          while (start_time.day < teacher_last_day_in_student_tz && start_time < end_time) do
            start_time = start_time + 1800
          end
          while (start_time + added_time <= end_time) do
            if available_times.empty?
              available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                              (Time.at(start_time).in_time_zone(params[:student_timezone])..(Time.at(start_time).in_time_zone(params[:student_timezone]) + added_time))
              start_time = (start_time + 1800)
            elsif (start_time + added_time <= end_time)
              available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                              (Time.at(start_time).in_time_zone(params[:student_timezone])..(Time.at(start_time).in_time_zone(params[:student_timezone]) + added_time))
              start_time = (start_time + 1800)
            end # if available_times.empty?
          end # while loop
        end # if teacher_start_day < teacher_last_day_in_student_tz
      end # before_time_frames.each
    end # if !before_time_frames.empty?
    if !after_time_frames.empty?
      after_time_frames.each do |tf|
        teacher_start_day = Time.at(tf[:time_range].first).in_time_zone(params[:teacher_timezone]).day
        teacher_start_day_in_student_tz = Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone]).day
        if teacher_start_day > teacher_start_day_in_student_tz
          start_time = Time.at(tf[:time_range].first).in_time_zone(params[:student_timezone])
          end_time = Time.at(tf[:time_range].last).in_time_zone(params[:student_timezone])
          while (end_time.day > teacher_start_day_in_student_tz && start_time < end_time)
            end_time = end_time - 1800
          end
          while (start_time + added_time <= end_time) do
            if available_times.empty?
              available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                              (Time.at(start_time).in_time_zone(params[:student_timezone])..(Time.at(start_time).in_time_zone(params[:student_timezone]) + added_time))
              start_time = (Time.at(start_time).in_time_zone(params[:student_timezone]) + 1800)
            elsif (start_time + added_time <= end_time)
              available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                              (Time.at(start_time).in_time_zone(params[:student_timezone])..(Time.at(start_time).in_time_zone(params[:student_timezone]) + added_time))
              start_time = (start_time + 1800)
            end # if available_times.empty?
          end # while loop
        end
      end # after_time_frames.each
    end # if !after_time_frames.empty?
    return available_times
  end

  def get_teacher_yoga_types
    yoga_types = YogaType.where(teacher_id: @teacher)
    @type_ids = []
    yoga_types.each do |yt|
      @type_ids << yt.type_id
    end
  end

  private

  def get_upcoming_yoga_sessions
    upcoming_yoga_sessions = {}
    next_booked_times = TeacherBookedTime.where("session_date >= ?", Date.today).where(teacher_id: @teacher).limit(15).order(session_date: :asc)
    if next_booked_times.empty?
      return "no-upcoming-sessions"
    else
      counter = 1
      next_booked_times.each do |bt|
        yoga_session = YogaSession.where(teacher_booked_time_id: bt).first
        next if yoga_session.nil?
        student = Student.find(yoga_session[:student_id])
        date = sanitize_date_for_view(bt[:session_date].to_s)
        day_of_week = bt[:session_date].strftime("%A")
        split_date = bt[:session_date].to_s.split("-")
        Time.zone = bt[:teacher_timezone]
        time_range = sanitize_date_range_for_view(bt[:time_range], bt[:student_timezone])
        split_time_range = time_range.split(" - ")
        start_time = sanitize_date_for_time_only(Time.parse(split_time_range[0]).in_time_zone(bt[:teacher_timezone]))
        end_time = sanitize_date_for_time_only((Time.parse(split_time_range[1]) - 1).in_time_zone(bt[:teacher_timezone]))
        timestamp_time = Time.parse(split_time_range[0]).in_time_zone(bt[:teacher_timezone])
        timestamp = Time.zone.local(split_date[0], split_date[1], split_date[2], timestamp_time.strftime("%k"), timestamp_time.strftime("%M"))
        upcoming_yoga_sessions["yoga_session_#{counter}"] = {}
        upcoming_yoga_sessions["yoga_session_#{counter}"]["yoga_session_id"] = yoga_session[:id]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["yoga_type"] = YogaType::ENUMS.key(yoga_session[:yoga_type])
        upcoming_yoga_sessions["yoga_session_#{counter}"]["first_name"] = student[:first_name]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["last_name"] = student[:last_name]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["date"] = date
        upcoming_yoga_sessions["yoga_session_#{counter}"]["cancelled"] = yoga_session[:teacher_cancelled_session]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["day_of_week"] = day_of_week
        upcoming_yoga_sessions["yoga_session_#{counter}"]["time_range"] = "#{start_time} - #{end_time}"
        upcoming_yoga_sessions["yoga_session_#{counter}"]["duration"] = bt[:duration]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["timezone"] = bt[:teacher_timezone]
        upcoming_yoga_sessions["yoga_session_#{counter}"]["timestamp"] = timestamp
        upcoming_yoga_sessions["yoga_session_#{counter}"]["refunded"] = yoga_session[:student_refund_given]
        counter += 1
      end
      return sorted = upcoming_yoga_sessions.sort_by{|k, v| v["timestamp"]}
    end
  end

  def teacher_params
    params.require(:teacher).permit(:first_name, :last_name, :phone, :timezone, :profile_pic, :is_searchable, :is_verified, :blacklisted, :has_been_blacklisted, :unblackist_date, :blocked, :vacation_mode, :certificate, :bio)
  end
end
