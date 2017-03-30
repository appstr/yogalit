class AddAttachmentImageToTeacherImages < ActiveRecord::Migration
  def self.up
    change_table :teacher_images do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :teacher_images, :image
  end
end
