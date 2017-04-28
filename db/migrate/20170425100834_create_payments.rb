class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.belongs_to :student, index: true
      t.belongs_to :teacher, index: true
      t.float :sales_tax
      t.float :price_without_tax
      t.float :total_price
      t.timestamps null: false
    end
  end
end
