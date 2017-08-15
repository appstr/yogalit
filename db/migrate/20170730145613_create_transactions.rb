class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.belongs_to :disbursement, index: true
      t.string :trans_id
      t.timestamps null: false
    end
  end
end
