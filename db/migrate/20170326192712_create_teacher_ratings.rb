class CreateTeacherRatings < ActiveRecord::Migration
  def change
    create_table :teacher_ratings do |t|
      t.belongs_to :teacher, index: true
      t.belongs_to :student, index: true
      t.integer :score
      t.string :comment
      t.timestamps null: false
    end
  end
end
