class CreateYogaSessions < ActiveRecord::Migration[5.1]
  def change
    create_table :yoga_sessions do |t|
      t.belongs_to :payment, index: true
      t.belongs_to :teacher, index: true
      t.belongs_to :student, index: true
      t.belongs_to :teacher_booked_time, index: true
      t.string :opentok_session_id
      t.boolean :teacher_payout_made
      t.boolean :video_under_review
      t.boolean :video_reviewed
      t.boolean :teacher_cancelled_session
      t.boolean :student_requested_refund
      t.boolean :student_refund_given
      t.integer :yoga_type
      t.timestamps null: false
    end
  end
end
