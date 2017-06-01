module ApplicationHelper
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

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

  def credit_card_type_options
    [
      ["Visa", "visa"],
      ["MasterCard", "MasterCard"],
      ["American Express", "american_express"],
      ["Discover", "discover"],
    ]
  end

  def state_options
    [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end

  def time_frame_options
    time_frames = []
    initial_time = Time.zone.local(2017, 01, 01, 00, 00, 00)
    start_time = Time.zone.local(2017, 01, 01, 00, 00, 00)
    while start_time.wday == initial_time.wday
      time_frames << [sanitize_date_for_time_only(start_time), sanitize_date_for_time_only(start_time)]
      if sanitize_date_for_time_only(start_time) == "11:30pm"
        start_time += 1799
      else
        start_time += 1800
      end
    end
    return time_frames
  end

  def teacher_score_options
    [
      ["1", 1],
      ["2", 2],
      ["3", 3],
      ["4", 4],
      ["5", 5]
    ]
  end

  def month_exp_options
    [
      ["01", "01"],
      ["02", "02"],
      ["03", "03"],
      ["04", "04"],
      ["05", "05"],
      ["06", "06"],
      ["07", "07"],
      ["08", "08"],
      ["09", "09"],
      ["10", "10"],
      ["11", "11"],
      ["12", "12"]
    ]
  end

  def year_exp_options
    this_year = Time.now.strftime("%Y").to_i
    end_year = this_year + 15
    opts = []
    while this_year <= end_year
      opts << [this_year.to_s, this_year.to_s]
      this_year += 1
    end
    return opts
  end

end
