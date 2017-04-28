class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

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
end
