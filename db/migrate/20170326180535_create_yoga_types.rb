class CreateYogaTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :yoga_types do |t|
      t.belongs_to :teacher, index: true
      t.integer :type_id
      t.timestamps null: false
    end
  end
end
