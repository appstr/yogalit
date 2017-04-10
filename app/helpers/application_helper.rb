module ApplicationHelper
  def sanitize_date_for_time_only(date)
    # returns time from date. --> 9:00pm
    return date.strftime("%l:%M%P")
  end

  def sanitize_date_for_view(date_range, timezone)
    start_date = Time.at(date_range.first).in_time_zone(timezone)
    end_date = Time.at(date_range.last).in_time_zone(timezone)
    return "#{start_date} - #{end_date}"
  end
end
