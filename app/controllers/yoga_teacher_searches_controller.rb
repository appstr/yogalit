class YogaTeacherSearchesController < ApplicationController
  # before_action :authenticate_user!
  def search_for_teachers
    if params[:date]
      yoga_teacher_ids = yoga_teacher_ids_matching_yoga_type
      if yoga_teacher_ids.blank?
        @yoga_teachers = nil
      else
        yoga_teacher_ids = yoga_teachers_not_on_holiday(yoga_teacher_ids, search_date=nil)
        @yoga_type = YogaType::ENUMS.key(params[:type_of_yoga].to_i)
        @duration = params[:duration]
        @student_timezone = params["student_timezone"].first
        @session_date = Time.parse(Date.parse(params[:date]).to_s)
        @day_of_week = @session_date.strftime("%A")
        yoga_teacher_ids = yoga_teachers_available_on(@day_of_week, yoga_teacher_ids, nil, nil, params[:time_frame])
        @yoga_teachers = get_filtered_teachers(yoga_teacher_ids)
      end
    else
      @yoga_teachers = nil
    end
  end

  def get_filtered_teachers(yoga_teacher_ids)
    yoga_teachers = []
    yoga_teacher_ids.each do |yi|
      yoga_teachers << Teacher.find(yi)
    end
    return yoga_teachers
  end

  def yoga_teachers_available_on(day_of_week, yoga_teacher_ids, date = nil, student_timezone = nil, student_time_frame)
    split_time = student_time_frame.split(" - ")
    @student_timezone = student_timezone if @student_timezone.nil?
    Time.zone = @student_timezone
    if @year.nil?
      if date.nil?
        date = Time.parse(params[:date])
      else
        date = Time.parse(date)
      end
      @year = date.strftime("%Y").to_i
      @month = date.strftime("%m").to_i
      @day = date.strftime("%d").to_i
    end
    date = Time.zone.local(@year, @month, @day)
    start_time = Time.parse(split_time.first, date)
    end_time = Time.parse(split_time.last, date)
    student_time_frame = Time.zone.local(@year, @month, @day, start_time.strftime("%k"), start_time.strftime("%M"))..Time.zone.local(@year, @month, @day, end_time.strftime("%k"), end_time.strftime("%M"))
    @student_time_frame = student_time_frame
    new_ids = []
    if day_of_week == "Monday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherSundayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherMondayTimeFrame.where(teacher_id: yi)
        after_times = TeacherTuesdayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Tuesday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherMondayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherTuesdayTimeFrame.where(teacher_id: yi)
        after_times = TeacherWednesdayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Wednesday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherTuesdayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherWednesdayTimeFrame.where(teacher_id: yi)
        after_times = TeacherThursdayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Thursday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherWednesdayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherThursdayTimeFrame.where(teacher_id: yi)
        after_times = TeacherFridayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Friday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherThursdayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherFridayTimeFrame.where(teacher_id: yi)
        after_times = TeacherSaturdayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Saturday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherFridayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherSaturdayTimeFrame.where(teacher_id: yi)
        after_times = TeacherSundayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    elsif day_of_week == "Sunday"
      yoga_teacher_ids.each do |yi|
        teacher = Teacher.find(yi)
        before_times = TeacherSaturdayTimeFrame.where(teacher_id: yi)
        time_frames = TeacherSundayTimeFrame.where(teacher_id: yi)
        after_times = TeacherMondayTimeFrame.where(teacher_id: yi)
        if check_hoo(student_time_frame, teacher, before_times, "before") || check_hoo(student_time_frame, teacher, time_frames, "current") || check_hoo(student_time_frame, teacher, after_times, "after")
          if check_booked_times(student_time_frame, teacher)
            new_ids << yi if !new_ids.include?(yi)
          end
        end
      end
    end
    return new_ids
  end

  def check_hoo(student_time_frame, teacher, hoo, before_current_after)
    return false if hoo.blank?
    Time.zone = teacher[:timezone]
    stf = student_time_frame
    hoo.each do |h|
      t = Time.at(h.time_range.first).in_time_zone(teacher[:timezone])..Time.at(h.time_range.last).in_time_zone(teacher[:timezone])
      t = (t.first..(t.last + 60)) if t.last.strftime("%M").to_i == 59
      if before_current_after == "before"
        if t.first.wday == t.last.wday
          teacher_time_frame = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d").to_i - 1, t.first.strftime("%k"), t.first.strftime("%M"))..teacher_tz = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d").to_i - 1, t.last.strftime("%k"), t.last.strftime("%M"))
        else
          teacher_time_frame = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d").to_i - 1, t.first.strftime("%k"), t.first.strftime("%M"))..teacher_tz = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d"), t.last.strftime("%k"), t.last.strftime("%M"))
        end
      elsif before_current_after == "current"
        teacher_time_frame = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d"), t.first.strftime("%k"), t.first.strftime("%M"))..teacher_tz = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d"), t.last.strftime("%k"), t.last.strftime("%M"))
        if teacher_time_frame.last.strftime("%k").to_i == 0 && teacher_time_frame.last.strftime("%M").to_i == 0
          teacher_time_frame = (teacher_time_frame.first..((teacher_time_frame.last - 60) + 86400))
        end
      else
        teacher_time_frame = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d").to_i + 1, t.first.strftime("%k"), t.first.strftime("%M"))..teacher_tz = Time.zone.local(stf.first.strftime("%Y"), stf.first.strftime("%m"), stf.first.strftime("%d").to_i + 1, t.last.strftime("%k"), t.last.strftime("%M"))
      end
      ttf = teacher_time_frame
      if stf.last.strftime("%k").to_i == 0 && stf.last.strftime("%M").to_i == 0
        stf = (stf.first..((stf.last - 60) + 86400))
      end
      if stf.first.between?(ttf.first, ttf.last) && stf.last.between?(ttf.first, ttf.last)
        if stf.first.in_time_zone(teacher[:timezone]) >= Time.now.in_time_zone(teacher[:timezone]) + 900
          return true
        end
      end
    end
    return false
  end

  def check_booked_times(student_time_frame, teacher)
    booked_times = TeacherBookedTime.where(teacher_id: teacher)
    return true if booked_times.blank?
    booked_times.each do |bt|
      session_date = Time.parse(bt.session_date.to_s)
      sd = session_date
      Time.zone = bt[:teacher_timezone]
      ttf = Time.zone.local(sd.strftime("%Y"), sd.strftime("%m"), sd.strftime("%d"), bt.time_range.first.in_time_zone(bt[:teacher_timezone]).strftime("%k"), bt.time_range.first.in_time_zone(bt[:teacher_timezone]).strftime("%M"))..Time.zone.local(sd.strftime("%Y"), sd.strftime("%m"), sd.strftime("%d"), bt.time_range.last.in_time_zone(bt[:teacher_timezone]).strftime("%k"), (bt.time_range.last - 1).in_time_zone(bt[:teacher_timezone]).strftime("%M"))
      if student_time_frame.first.between?(ttf.first.in_time_zone(bt[:student_timezone]), (ttf.last - 1).in_time_zone(bt[:student_timezone]))
        return false
      elsif student_time_frame.last.between?((ttf.first).in_time_zone(bt[:student_timezone]), ttf.last.in_time_zone(bt[:student_timezone]))
        return false
      elsif ttf.first.between?(student_time_frame.first, student_time_frame.last)
        return false
      elsif ttf.last.between?(student_time_frame.first + 1, student_time_frame.last)
        return false
      end
    end
    return true
  end

  def yoga_teachers_not_on_holiday(yoga_teacher_ids, search_date = nil)
    new_ids = []
    yoga_teacher_ids.each do |yi|
      holidays = TeacherHoliday.where(teacher_id: yi)
      if holidays.empty?
        new_ids << yi
      else
        holidays.each do |hday|
          search_date = format_search_date(hday[:teacher_id]) if search_date.nil?
          holiday_date_range = Time.at(hday[:holiday_date_range].first).in_time_zone(hday[:teacher_timezone])..Time.at(hday[:holiday_date_range].last).in_time_zone(hday[:teacher_timezone])
          if !search_date.between?(Time.parse(holiday_date_range.first.to_s), Time.parse(holiday_date_range.last.to_s)) && !new_ids.include?(yi)
            new_ids << yi
          end
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
        merchant_account_active = teacher.merchant_account_active
        yoga_instructor_ids << yt[:teacher_id] if is_searchable && is_verified && !is_blacklisted && !is_blocked && merchant_account_active
      end
    end
    return yoga_instructor_ids
  end

  def format_search_date(teacher_id)
    teacher = Teacher.find(teacher_id)
    split_date = params[:date].split(" ")
    @month = YogaTeacherSearch::DATE_ENUMS[split_date[1].delete(",")]
    @day = split_date[0].to_i
    @year = split_date[2].to_i
    Time.zone = teacher[:timezone]
    return Time.zone.local(@year, @month, @day, 00, 00)
  end
end
