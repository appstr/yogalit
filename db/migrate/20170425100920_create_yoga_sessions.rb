class CreateYogaSessions < ActiveRecord::Migration
  def change
    create_table :yoga_sessions do |t|
      t.belongs_to :payment, index: true
      t.belongs_to :teacher, index: true
      t.belongs_to :student, index: true
      t.belongs_to :teacher_booked_time, index: true
      t.string :opentok_session_id
      t.string :transaction_id
      t.string :opentok_archive_id
      t.timestamps null: false
    end
  end
end
