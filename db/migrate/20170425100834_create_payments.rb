class CreatePayments < ActiveRecord::Migration[5.1]
  def change
    create_table :payments do |t|
      t.belongs_to :student, index: true
      t.belongs_to :teacher, index: true
      t.float :sales_tax
      t.float :price_without_tax
      t.float :total_price
      t.float :yogalit_tax
      t.float :yogalit_fee_amount
      t.float :teacher_payout_amount
      t.string :transaction_id
      t.timestamps null: false
    end
  end
end
