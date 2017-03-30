module ApplicationHelper
  def sanitize_date_for_time_only(date)
    # returns time from date. --> 9:00pm
    return date.strftime("%l:%M%P")
  end

  def sanitize_date_for_view(date)
    # sanitizes date for view. --> "2017-03-31" formatted to: "03/31/2017"
    new_date = []
    split_date = date.to_s.split("-")
    new_date << split_date[1]
    new_date << split_date[2]
    new_date << split_date[0]
    return new_date.join("/")
  end
end
