class AddAttachmentProfilePicToTeachers < ActiveRecord::Migration[5.1]
  def self.up
    change_table :teachers do |t|
      t.attachment :profile_pic
    end
  end

  def self.down
    remove_attachment :teachers, :profile_pic
  end
end
