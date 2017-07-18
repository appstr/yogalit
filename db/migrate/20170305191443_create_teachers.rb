class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.belongs_to :user, index: true
      t.string  :first_name
      t.string  :last_name
      t.string  :phone
      t.string  :bio
      t.string  :timezone
      t.float   :average_rating
      t.boolean :is_searchable
      t.boolean :is_verified
      t.boolean :blacklisted
      t.date    :unblacklist_date
      t.boolean :has_been_blacklisted
      t.boolean :blocked
      t.boolean :vacation_mode
      t.string  :payout_type
      t.boolean :registered_business
      t.string  :merchant_account_id
      t.boolean :merchant_account_requested
      t.boolean :merchant_account_active
      t.timestamps null: false
    end
  end
end
