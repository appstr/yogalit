class AddAttachmentVideoToTeacherVideos < ActiveRecord::Migration
  def self.up
    change_table :teacher_videos do |t|
      t.attachment :video
    end
  end

  def self.down
    remove_attachment :teacher_videos, :video
  end
end
