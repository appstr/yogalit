class TeachersController < ApplicationController
  before_action :authenticate_user!
  include ApplicationHelper

  def index
    @teacher = Teacher.where(user_id: current_user).first
    # Returns an array of type_ids associated to the Teacher --> @type_ids
    get_teacher_yoga_types
    # Teacher Images
    @teacher_image = TeacherImage.new
    @teacher_images = TeacherImage.where(teacher_id: @teacher)
    # Teacher Videos
    @teacher_video = TeacherVideo.new
    @teacher_videos = TeacherVideo.where(teacher_id: @teacher)
    @teacher_price_range_form = TeacherPriceRange.new
    @teacher_price_ranges = TeacherPriceRange.where(teacher_id: @teacher).first
  end

  def new
    return redirect_to teachers_path if Teacher.teacher_exists?(current_user)
    @teacher = Teacher.new
  end

  def create
    params[:teacher][:first_name].downcase!
    params[:teacher][:last_name].downcase!
    teacher = Teacher.new(teacher_params)
    teacher[:user_id] = current_user[:id]
    teacher[:average_rating] = 0
    path = teacher.save! ? teachers_path : request.referrer
    return redirect_to path
  end

  def edit
    @teacher = Teacher.find(params[:id])
  end

  def update
    teacher = Teacher.find(params[:id])
    teacher[:first_name] = params[:teacher][:first_name].downcase
    teacher[:last_name] = params[:teacher][:last_name].downcase
    teacher[:phone] = params[:teacher][:phone]
    teacher[:timezone] = params[:teacher][:timezone]
    teacher.profile_pic = params[:teacher][:profile_pic] if !params[:teacher][:profile_pic].nil?
    if teacher.save!
      flash[:notice] = "Your profile info was update successfully!"
      path = teachers_path
    else
      flash[:notice] = "Your profile info was not updated."
      path = request.referrer
    end
    return redirect_to path
  end

  def show
    @teacher = Teacher.find(params[:id])
    @teacher_price_ranges = TeacherPriceRange.where(teacher_id: @teacher).first
    duration = get_duration_in_seconds
    teacher_time_frames = get_teacher_time_frames_for(params[:day_of_week])
    available_booking_times = build_teacher_time_frame(teacher_time_frames, duration)
    extra_booking_times = get_teacher_extra_time_frames_for(params[:day_of_week], duration)
    available_booking_times = merge_booking_times(available_booking_times, extra_booking_times) if !extra_booking_times.nil?
    filtered_booking_times = get_res_filtered_booking_times(available_booking_times, duration)
    @filtered_booking_time_options = format_filtered_booking_times(filtered_booking_times)
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
    teacher_booked_times = TeacherBookedTime.where(teacher_id: @teacher).where('session_date = ?', Time.new(booking_date[0], booking_date[1], booking_date[2]))
    return remove_booked_times_from(available_booking_times, teacher_booked_times)
  end

  def remove_booked_times_from(available_booking_times, teacher_booked_times)
    filtered_times = available_booking_times
    available_booking_times.each do |av_bt|
      available_start = av_bt[1].first
      available_end = av_bt[1].last
      teacher_booked_times.each do |t_bt|
        booked_start = Time.at(t_bt[:time_range].first).in_time_zone(params[:student_timezone])
        booked_end = Time.at(t_bt[:time_range].last - 1).in_time_zone(params[:student_timezone])
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
    return remove_times_before_now(sorted_formatted_times) if Date.parse(params["session_date"]) == Date.today
    return sorted_formatted_times
  end

  def remove_times_before_now(sorted_formatted_times)
    new_times = []
    sorted_formatted_times.each do |obj|
      if !(obj[1].first.strftime("%k%M").to_i <= Time.now.in_time_zone(params[:student_timezone]).strftime("%k%M").to_i)
        new_times << [obj[0], obj[1]]
      end
    end
    return new_times
  end

  def build_teacher_time_frame(teacher_time_frames, added_time)
    available_times = {}
    start_time = Date.today
    end_time = Date.today
    Time.zone = params[:student_timezone]
    teacher_time_frames.each do |tf|
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

  def teacher_params
    params.require(:teacher).permit(:first_name, :last_name, :phone, :timezone, :profile_pic, :is_searchable)
  end
end
