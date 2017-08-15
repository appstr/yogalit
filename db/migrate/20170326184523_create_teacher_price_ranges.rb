class CreateTeacherPriceRanges < ActiveRecord::Migration[5.1]
  def change
    create_table :teacher_price_ranges do |t|
      t.belongs_to :teacher, index: true
      t.float :thirty_minute_session
      t.float :sixty_minute_session
      t.float :ninety_minute_session
      t.float :sales_tax
      t.timestamps null: false
    end
  end
end
