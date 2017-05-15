class CreateTeacherEmergencyCancels < ActiveRecord::Migration
  def change
    create_table :teacher_emergency_cancels do |t|
      t.belongs_to :teacher, index: true
      t.timestamps null: false
    end
  end
end
