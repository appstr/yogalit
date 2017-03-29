module ApplicationHelper
  def sanitize_date_for_time_only(date)
    return date.strftime("%l:%M%P")
  end
end
