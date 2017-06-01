class CreateTeacherRatings < ActiveRecord::Migration
  def change
    create_table :teacher_ratings do |t|
      t.belongs_to :yoga_session, index: true
      t.belongs_to :teacher, index: true
      t.float :score
      t.string :comment
      t.timestamps null: false
    end
  end
end
