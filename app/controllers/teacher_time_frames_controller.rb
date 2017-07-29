class TeacherTimeFramesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    teacher = Teacher.where(user_id: current_user).first
    split_start_time
    split_end_time
    get_day_of_week_info(teacher, params[:day_of_week])
    if end_less_than_start?(teacher)
      return render json: {success:false, message: "End time cannot be less than start time."}
    elsif start_equal_end?(teacher)
      return render json: {success:false, message: "Start time and end time cannot be equal."}
    end
    if time_frame_taken?(teacher, params[:day_of_week])
      return render json: {success:false, message: "Time frame given interferes with a previous time frame."}
    end
    Time.zone = teacher.timezone
    teacher_time_frame = @day_of_week_instance
    teacher_time_frame[:time_range] = (Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00)..Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00))
    teacher_time_frame[:teacher_id] = teacher[:id]
    if teacher_time_frame.save
      Teacher.qualifies_for_search?(current_user)
      return render json: {success:true, message:"TimeFrame saved successfully!", teacher_id: teacher[:id]}
    else
      return render json: {success:false, message: "TimeFrame did not save successfully."}
    end
  end

  def destroy
    teacher = find_teacher_tf_by(params[:day_of_week], params[:id])
    if teacher.delete
      flash[:notice] = "Your time-frame was deleted successfully!"
    else
      flash[:notice] = "Your time-frame was not deleted. Please try again"
    end
    Teacher.qualifies_for_search?(current_user)
    return redirect_to teachers_path
  end

  def find_teacher_tf_by(dow, id)
    if dow == "monday"
      i = TeacherMondayTimeFrame.find(id)
    elsif dow == "tuesday"
      i = TeacherTuesdayTimeFrame.find(id)
    elsif dow == "wednesday"
      i = TeacherWednesdayTimeFrame.find(id)
    elsif dow == "thursday"
      i = TeacherThursdayTimeFrame.find(id)
    elsif dow == "friday"
      i = TeacherFridayTimeFrame.find(id)
    elsif dow == "saturday"
      i = TeacherSaturdayTimeFrame.find(id)
    else
      i = TeacherSundayTimeFrame.find(id)
    end
    return i
  end

  def get_day_of_week_info(teacher, dow)
    @year = 2017
    if dow == "monday"
      @month = 03
      @day = 27
      @day_of_week_instance = TeacherMondayTimeFrame.new
      @dow_time_frame = TeacherMondayTimeFrame.where(teacher_id: teacher)
    elsif dow == "tuesday"
      @month = 03
      @day = 28
      @day_of_week_instance = TeacherTuesdayTimeFrame.new
      @dow_time_frame = TeacherTuesdayTimeFrame.where(teacher_id: teacher)
    elsif dow == "wednesday"
      @month = 03
      @day = 29
      @day_of_week_instance = TeacherWednesdayTimeFrame.new
      @dow_time_frame = TeacherWednesdayTimeFrame.where(teacher_id: teacher)
    elsif dow == "thursday"
      @month = 03
      @day = 30
      @day_of_week_instance = TeacherThursdayTimeFrame.new
      @dow_time_frame = TeacherThursdayTimeFrame.where(teacher_id: teacher)
    elsif dow == "friday"
      @month = 03
      @day = 31
      @day_of_week_instance = TeacherFridayTimeFrame.new
      @dow_time_frame = TeacherFridayTimeFrame.where(teacher_id: teacher)
    elsif dow == "saturday"
      @month = 04
      @day = 01
      @day_of_week_instance = TeacherSaturdayTimeFrame.new
      @dow_time_frame = TeacherSaturdayTimeFrame.where(teacher_id: teacher)
    else
      @month = 04
      @day = 02
      @day_of_week_instance = TeacherSundayTimeFrame.new
      @dow_time_frame = TeacherSundayTimeFrame.where(teacher_id: teacher)
    end
  end

  private

  def end_less_than_start?(teacher)
    if Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]) > Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00).in_time_zone(teacher[:timezone])
      return true
    else
      return false
    end
  end

  def start_equal_end?(teacher)
    if Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]) == Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00).in_time_zone(teacher[:timezone])
      return true
    else
      return false
    end
  end

  def time_frame_taken?(teacher, dow)
    time_frames = @dow_time_frame
    return false if time_frames.blank?
    time_frames.each do |tf|
      if (Time.at(tf[:time_range].first).in_time_zone(teacher[:timezone]).to_i..Time.at(tf[:time_range].last).in_time_zone(teacher[:timezone]).to_i).include? Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]).to_i
        return true
      elsif (Time.zone.local(@year, @month, @day, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]).to_i..Time.zone.local(@year, @month, @day, @end_hour, @end_minute, 00).in_time_zone(teacher[:timezone]).to_i).include? tf[:time_range].first
        return true
      end
    end
    return false
  end

end
