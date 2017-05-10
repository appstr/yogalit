class YogaTeacherSearchesController < ApplicationController
  before_action :authenticate_user!
  def search_for_teachers
    yoga_teacher_ids = yoga_teacher_ids_matching_yoga_type
    int_search_date = format_search_date_to_int
    yoga_teacher_ids = yoga_teachers_not_on_holiday(yoga_teacher_ids, int_search_date)
    @yoga_type = YogaType::ENUMS.key(params[:type_of_yoga].to_i)
    @duration = params[:duration]
    @student_timezone = params["student_timezone"]["time_zone"]
    @session_date = Time.new(@year, @month, @day)
    @day_of_week = @session_date.strftime("%A")
    yoga_teacher_ids = yoga_teachers_available_on(@day_of_week, yoga_teacher_ids)
    @yoga_teachers = get_filtered_teachers(yoga_teacher_ids)
  end


  def get_filtered_teachers(yoga_teacher_ids)
    yoga_teachers = []
    yoga_teacher_ids.each do |yi|
      yoga_teachers << Teacher.find(yi)
    end
    return yoga_teachers
  end

  def yoga_teachers_available_on(day_of_week, yoga_teacher_ids)
    new_ids = []
    if day_of_week == "Monday"
      yoga_teacher_ids.each do |yi|
        time_frames = TeacherMondayTimeFrame.where(teacher_id: yi).first
        new_ids << yi if !time_frames.nil?
      end
    elsif day_of_week == "Tuesday"
      yoga_teacher_ids.each do |yi|
        time_frames = TeacherTuesdayTimeFrame.where(teacher_id: yi).first
        new_ids << yi if !time_frames.nil?
      end
    elsif day_of_week == "Wednesday"
        yoga_teacher_ids.each do |yi|
          time_frames = TeacherWednesdayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil?
        end
    elsif day_of_week == "Thursday"
        yoga_teacher_ids.each do |yi|
          time_frames = TeacherThursdayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil?
        end
    elsif day_of_week == "Friday"
        yoga_teacher_ids.each do |yi|
          time_frames = TeacherFridayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil?
        end
    elsif day_of_week == "Saturday"
        yoga_teacher_ids.each do |yi|
          time_frames = TeacherSaturdayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil?
        end
    else day_of_week == "Sunday"
        yoga_teacher_ids.each do |yi|
          time_frames = TeacherSundayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil?
        end
    end
    return new_ids
  end

  def yoga_teachers_not_on_holiday(yoga_teacher_ids, int_search_date)
    new_ids = []
    yoga_teacher_ids.each do |yi|
      holidays = TeacherHoliday.where(teacher_id: yi)
      if holidays.empty?
        new_ids << yi
      else
        holidays.each do |hday|
          new_ids << yi if !hday[:holiday_date_range].include?(int_search_date)
        end
      end
    end
    return new_ids
  end

  def yoga_teacher_ids_matching_yoga_type
    yoga_instructor_ids = []
    yoga_types = YogaType.where(type_id: params[:type_of_yoga])
    yoga_types.each do |yt|
      if yoga_instructor_ids.empty? || !yoga_instructor_ids.include?(yt[:teacher_id])
        is_searchable = Teacher.find(yt[:teacher_id]).is_searchable
        is_verified = Teacher.find(yt[:teacher_id]).is_verified
        yoga_instructor_ids << yt[:teacher_id] if is_searchable && is_verified
      end
    end
    return yoga_instructor_ids
  end

  def format_search_date_to_int
    split_date = params[:date].split(" ")
    @month = YogaTeacherSearch::DATE_ENUMS[split_date[1].delete(",")]
    @day = split_date[0].to_i
    @year = split_date[2].to_i
    return Time.new(@year, @month, @day).to_i
  end
end
