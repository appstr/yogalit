module ApplicationHelper
  def sanitize_date_for_time_only(date)
    # returns time from date (zero-padded). --> 09:00pm
    return date.strftime("%I:%M%P")
  end

  def sanitize_date_range_for_view(date_range, timezone)
    start_date = Time.at(date_range.first).in_time_zone(timezone)
    end_date = Time.at(date_range.last).in_time_zone(timezone)
    return "#{start_date} - #{end_date}"
  end

  def sanitize_date_for_view(date)
    # date is passed in as a string
    new_date = []
    date = date.split(" ")[0]
    date = date.split("-")
    new_date << date[1]
    new_date << date[2]
    new_date << date[0]
    return new_date.join("-")
  end

  def yoga_type_options
    [
      ["Bikram", 1],
      ["Ashtanga", 2],
      ["Beginner Yoga", 3],
      ["Fusion", 4],
      ["Hatha", 5],
      ["Kids", 6],
      ["Kundalini", 7],
      ["Kundalini", 8],
      ["Power", 9],
      ["Pre/Postnatal", 10],
      ["Restorative", 11],
      ["Vinyasa", 12],
      ["Yin", 13],
      ["Yoga at Work", 14],
      ["Yoga for Seniors", 15],
      ["Pilates", 16],
      ["Iyengar", 17]
    ]
  end

  def yoga_session_duration_options
    [
      ["30 minutes", 30],
      ["60 minutes", 60],
      ["90 minutes", 90]
    ]
  end
end
