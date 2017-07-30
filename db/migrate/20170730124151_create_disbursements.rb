class CreateDisbursements < ActiveRecord::Migration
  def change
    create_table :disbursements do |t|
      t.belongs_to :teacher, index: true
      t.string :braintree_disbursement_id
      t.float :amount
      t.date :date_of_disbursement
      t.boolean :successful_disbursement
      t.string :exception_message
      t.string :follow_up_action
      t.timestamps null: false
    end
  end
end
