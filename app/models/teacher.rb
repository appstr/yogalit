class Teacher < ActiveRecord::Base
  belongs_to :user
  has_many :yoga_types
  has_many :teacher_holidays
  has_many :teacher_ratings
  has_many :teacher_monday_time_frames
  has_many :teacher_tuesday_time_frames
  has_many :teacher_wednesday_time_frames
  has_many :teacher_thursday_time_frames
  has_many :teacher_friday_time_frames
  has_many :teacher_saturday_time_frames
  has_many :teacher_sunday_time_frames
  has_one :teacher_price_range
end
