class CreateTeacherBookedTimes < ActiveRecord::Migration
  def change
    create_table :teacher_booked_times do |t|
      t.belongs_to :teacher, index: true
      t.belongs_to :student, index: true
      t.date :session_date
      t.tstzrange :time_range
      t.integer :duration
      t.string :student_timezone
      t.string :teacher_timezone
      t.timestamps null: false
    end
  end
end
