class TeacherSaturdayTimeFramesController < ApplicationController
  before_action :authenticate_user!

  def new
    @teacher = Teacher.where(user_id: current_user).first

    @teacher_saturday_time_frame = TeacherSaturdayTimeFrame.new

    teacher = Teacher.where(user_id: current_user).first
    @teacher_saturday_time_frames = TeacherSaturdayTimeFrame.where(teacher_id: teacher)
  end

  def create
    teacher = Teacher.where(user_id: current_user).first
    split_start_time
    split_end_time
    if end_less_than_start?(teacher)
      flash[:notice] = "End time cannot be less than start time."
      return redirect_to request.referrer
    end
    if time_frame_taken?(teacher)
      flash[:notice] = "Time frame given interferes with a previous time frame."
      return redirect_to request.referrer
    end
    Time.zone = teacher.timezone
    teacher_saturday_time_frame = TeacherSaturdayTimeFrame.new
    teacher_saturday_time_frame[:time_range] = (Time.zone.local(2017, 04, 01, @start_hour, @start_minute, 00)..Time.zone.local(2017, 04, 01, @end_hour, @end_minute, 00))
    teacher_saturday_time_frame[:teacher_id] = teacher[:id]
    if teacher_saturday_time_frame.save!
      Teacher.qualifies_for_search?(current_user)
      if params[:commit] == "Save and Add Another TimeFrame"
        flash[:notice] = "TimeFrame saved successfully!"
        path = request.referrer
      else
        flash[:notice] = "TimeFrame saved successfully!"
        path = teachers_path
      end
    else
      flash[:notice] = "TimeFrame did not save successfully."
      path = request.referrer
    end
    return redirect_to path
  end

  def destroy
    TeacherSaturdayTimeFrame.find(params[:id]).delete
    Teacher.qualifies_for_search?(current_user)
    return redirect_to request.referrer
  end

  private

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

  def end_less_than_start?(teacher)
    if Time.zone.local(2017, 04, 01, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]) > Time.zone.local(2017, 04, 01, @end_hour, @end_minute, 00).in_time_zone(teacher[:timezone])
      return true
    else
      return false
    end
  end

  def time_frame_taken?(teacher)
    time_frames = TeacherSaturdayTimeFrame.where(teacher_id: teacher)
    return false if time_frames.blank?
    time_frames.each do |tf|
      if (tf[:time_range].first..tf[:time_range].last).include? Time.zone.local(2017, 04, 01, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]).to_i
        return true
      elsif (Time.zone.local(2017, 04, 01, @start_hour, @start_minute, 00).in_time_zone(teacher[:timezone]).to_i..Time.zone.local(2017, 04, 01, @end_hour, @end_minute, 00).in_time_zone(teacher[:timezone]).to_i).include? tf[:time_range].first
        return true
      end
    end
    return false
  end

  def teacher_saturday_time_frame_params
    params.require(:teacher_saturday_time_frame).permit(:teacher_id, :time_range)
  end
end
