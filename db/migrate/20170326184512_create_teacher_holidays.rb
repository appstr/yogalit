class CreateTeacherHolidays < ActiveRecord::Migration
  def change
    create_table :teacher_holidays do |t|
      t.belongs_to :teacher, index: true
      t.date :holiday_date
      t.string :description
      t.timestamps null: false
    end
  end
end
