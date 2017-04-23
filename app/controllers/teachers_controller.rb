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
    @teacher_time_frames = get_teacher_time_frames_for(params[:day_of_week])
    @student = Student.where(user_id: current_user).first
    if params[:duration] == "30"
      duration = 1800
    elsif params[:duration] == "60"
      duration = 3600
    elsif params[:duration] == "90"
      duration = 5400
    end
    available_booking_times = build_teacher_time_frame(duration)
    filtered_booking_times = get_res_filtered_booking_times(available_booking_times, duration)
    @filtered_booking_time_options = format_filtered_booking_times(filtered_booking_times)
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
        booked_start = Time.at(t_bt[:time_range].first).in_time_zone(@student[:timezone])
        booked_end = Time.at(t_bt[:time_range].last).in_time_zone(@student[:timezone])
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
    return formatted_times
  end

  def build_teacher_time_frame(added_time)
    available_times = {}
    start_time = Date.today
    end_time = Date.today
    Time.zone = @student[:timezone]
    @teacher_time_frames.each do |tf|
      start_time = (Time.at(tf[:time_range].first).in_time_zone(@student[:timezone]))
      end_time = Time.at(tf[:time_range].last).in_time_zone(@student[:timezone])
      while (start_time + added_time <= end_time) do
        if available_times.empty?
          available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                          (Time.at(tf[:time_range].first).in_time_zone(@student[:timezone])..(Time.at(tf[:time_range].first).in_time_zone(@student[:timezone]) + added_time))
          start_time = (Time.at(tf[:time_range].first).in_time_zone(@student[:timezone]) + 1800)
        elsif (start_time + added_time <= end_time)
          available_times[("#{sanitize_date_for_time_only(start_time)} - #{sanitize_date_for_time_only(start_time + added_time)}")] =
                          (Time.at(start_time).in_time_zone(@student[:timezone])..(Time.at(start_time).in_time_zone(@student[:timezone]) + added_time))
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

  private

  def get_teacher_yoga_types
    yoga_types = YogaType.where(teacher_id: @teacher)
    @type_ids = []
    yoga_types.each do |yt|
      @type_ids << yt.type_id
    end
  end

  def teacher_params
    params.require(:teacher).permit(:first_name, :last_name, :phone, :timezone, :profile_pic)
  end
end
