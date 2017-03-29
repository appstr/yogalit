class CreateTeacherTimeFrameBlacklists < ActiveRecord::Migration
  def change
    create_table :teacher_time_frame_blacklists do |t|

      t.timestamps null: false
    end
  end
end
