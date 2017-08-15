class CreateSubMerchants < ActiveRecord::Migration[5.1]
  def change
    create_table :sub_merchants do |t|
      t.belongs_to :teacher, index: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :date_of_birth
      t.string :street_address
      t.string :locality
      t.string :region
      t.string :postal_code
      t.string :payout_type
      t.boolean :registered_business
      t.string :legal_name
      t.timestamps null: false
    end
  end
end
