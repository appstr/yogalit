class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.belongs_to :user, index: true
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :timezone
      t.bigint :average_rating
      t.boolean :is_searchable
      t.boolean :is_verified
      t.boolean :vacation_mode
      t.timestamps null: false
    end
  end
end
