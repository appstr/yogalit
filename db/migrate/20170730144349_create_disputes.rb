class CreateDisputes < ActiveRecord::Migration
  def change
    create_table :disputes do |t|
      t.belongs_to :disbursement, index: true
      t.string :braintree_dispute_id
      t.float :amount_requested
      t.date :received_date
      t.date :reply_date
      t.date :date_opened
      t.date :date_won
      t.string :status
      t.string :reason
      t.string :trans_id
      t.float :trans_amount
      t.timestamps null: false
    end
  end
end
