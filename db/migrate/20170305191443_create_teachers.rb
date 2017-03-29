class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.belongs_to :user, index: true
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :timezone
      t.timestamps null: false
    end
  end
end
