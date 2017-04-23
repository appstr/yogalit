class CreateTeacherBookedTimes < ActiveRecord::Migration
  def change
    create_table :teacher_booked_times do |t|
      t.belongs_to :teacher, index: true
      t.date :session_date
      t.int8range :time_range
      t.integer :duration
      t.timestamps null: false
    end
  end
end
