class CreateTeacherImages < ActiveRecord::Migration[5.1]
  def change
    create_table :teacher_images do |t|
      t.belongs_to :teacher, index: true
      t.timestamps null: false
    end
  end
end
