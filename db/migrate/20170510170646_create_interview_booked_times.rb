class CreateInterviewBookedTimes < ActiveRecord::Migration[5.1]
  def change
    create_table :interview_booked_times do |t|
      t.belongs_to :teacher, index: true
      t.date :interview_date
      t.tstzrange :time_range
      t.string :teacher_timezone
      t.boolean :teacher_cancelled
      t.boolean :completed
      t.timestamps null: false
    end
  end
end
