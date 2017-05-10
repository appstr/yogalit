class CreateInterviewBookedTimes < ActiveRecord::Migration
  def change
    create_table :interview_booked_times do |t|
      t.belongs_to :teacher, index: true
      t.date :interview_date
      t.int8range :time_range
      t.string :teacher_timezone
      t.timestamps null: false
    end
  end
end
