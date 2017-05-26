class YogaTeacherSearchesController < ApplicationController
  # before_action :authenticate_user!
  def search_for_teachers
    if params[:date]
      yoga_teacher_ids = yoga_teacher_ids_matching_yoga_type
      int_search_date = format_search_date_to_int
      yoga_teacher_ids = yoga_teachers_not_on_holiday(yoga_teacher_ids, int_search_date)
      @yoga_type = YogaType::ENUMS.key(params[:type_of_yoga].to_i)
      @duration = params[:duration]
      @student_timezone = params["student_timezone"].first
      @session_date = Time.new(@year, @month, @day)
      @day_of_week = @session_date.strftime("%A")
      yoga_teacher_ids = yoga_teachers_available_on(@day_of_week, yoga_teacher_ids)
      @yoga_teachers = get_filtered_teachers(yoga_teacher_ids)
    else
      @yoga_teachers = nil
      @first_ten_yoga_teachers = Teacher.where("id < ?", 11)
    end
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
        before_times = TeacherSundayTimeFrame.where(teacher_id: yi)
        before_times.each do |bt|
          if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
            new_ids << yi if !before_times.nil? && new_ids.include?(yi)
          end
        end
        time_frames = TeacherMondayTimeFrame.where(teacher_id: yi).first
        new_ids << yi if !time_frames.nil?
        after_times = TeacherTuesdayTimeFrame.where(teacher_id: yi)
        after_times.each do |at|
          if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
            new_ids << yi if !after_times.nil?
          end
        end
      end
    elsif day_of_week == "Tuesday"
      yoga_teacher_ids.each do |yi|
        before_times = TeacherMondayTimeFrame.where(teacher_id: yi)
        before_times.each do |bt|
          if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
            new_ids << yi if !before_times.nil? && !new_ids.include?(yi)
          end
        end
        time_frames = TeacherTuesdayTimeFrame.where(teacher_id: yi).first
        new_ids << yi if !time_frames.nil? && !new_ids.include?(yi)
        after_times = TeacherWednesdayTimeFrame.where(teacher_id: yi)
        after_times.each do |at|
          if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
            new_ids << yi if !after_times.nil? && !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Wednesday"
        yoga_teacher_ids.each do |yi|
          before_times = TeacherTuesdayTimeFrame.where(teacher_id: yi)
          before_times.each do |bt|
            if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !before_times.nil? && !new_ids.include?(yi)
            end
          end
          time_frames = TeacherWednesdayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil? && !new_ids.include?(yi)
          after_times = TeacherThursdayTimeFrame.where(teacher_id: yi)
          after_times.each do |at|
            if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !after_times.nil? && !new_ids.include?(yi)
            end
          end
        end
    elsif day_of_week == "Thursday"
        yoga_teacher_ids.each do |yi|
          before_times = TeacherWednesdayTimeFrame.where(teacher_id: yi)
          before_times.each do |bt|
            if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !before_times.nil? && !new_ids.include?(yi)
            end
          end
          time_frames = TeacherThursdayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil? && !new_ids.include?(yi)
          after_times = TeacherFridayTimeFrame.where(teacher_id: yi)
          after_times.each do |at|
            if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !after_times.nil? && !new_ids.include?(yi)
            end
          end
        end
    elsif day_of_week == "Friday"
        yoga_teacher_ids.each do |yi|
          before_times = TeacherThursdayTimeFrame.where(teacher_id: yi)
          before_times.each do |bt|
            if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !before_times.nil? && !new_ids.include?(yi)
            end
          end
          time_frames = TeacherFridayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil? && !new_ids.include?(yi)
          after_times = TeacherSaturdayTimeFrame.where(teacher_id: yi)
          after_times.each do |at|
            if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !after_times.nil? && !new_ids.include?(yi)
            end
          end
        end
    elsif day_of_week == "Saturday"
        yoga_teacher_ids.each do |yi|
          before_times = TeacherFridayTimeFrame.where(teacher_id: yi)
          before_times.each do |bt|
            if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !before_times.nil? && !new_ids.include?(yi)
            end
          end
          time_frames = TeacherSaturdayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil? && !new_ids.include?(yi)
          after_times = TeacherSundayTimeFrame.where(teacher_id: yi)
          after_times.each do |at|
            if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !after_times.nil? && !new_ids.include?(yi)
            end
          end
        end
    else day_of_week == "Sunday"
        yoga_teacher_ids.each do |yi|
          before_times = TeacherSaturdayTimeFrame.where(teacher_id: yi)
          before_times.each do |bt|
            if Time.at(bt[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !before_times.nil? && !new_ids.include?(yi)
            end
          end
          time_frames = TeacherSundayTimeFrame.where(teacher_id: yi).first
          new_ids << yi if !time_frames.nil? && !new_ids.include?(yi)
          after_times = TeacherMondayTimeFrame.where(teacher_id: yi)
          after_times.each do |at|
            if Time.at(at[:time_range].last).in_time_zone(@student_timezone).wday == Date.parse(params[:date]).wday
              new_ids << yi if !after_times.nil? && !new_ids.include?(yi)
            end
          end
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
        teacher = Teacher.find(yt[:teacher_id])
        is_searchable = teacher.is_searchable
        is_verified = teacher.is_verified
        is_blacklisted = teacher.blacklisted
        is_blocked = teacher.blocked
        yoga_instructor_ids << yt[:teacher_id] if is_searchable && is_verified && !is_blacklisted && !is_blocked
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
