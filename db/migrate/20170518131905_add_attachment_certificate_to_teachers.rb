class AddAttachmentCertificateToTeachers < ActiveRecord::Migration
  def self.up
    change_table :teachers do |t|
      t.attachment :certificate
    end
  end

  def self.down
    remove_attachment :teachers, :certificate
  end
end
