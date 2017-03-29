class CreateTeacherPriceRanges < ActiveRecord::Migration
  def change
    create_table :teacher_price_ranges do |t|
      t.float :thirty_minute_session
      t.float :sixty_minute_session
      t.float :ninety_minute_session
      t.timestamps null: false
    end
  end
end
