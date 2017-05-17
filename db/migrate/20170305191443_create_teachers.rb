class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.belongs_to :user, index: true
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :timezone
      t.string :paypal_email
      t.bigint :average_rating
      t.boolean :is_searchable
      t.boolean :is_verified
      t.boolean :blacklisted
      t.date    :unblacklist_date
      t.boolean :has_been_blacklisted
      t.boolean :blocked
      t.boolean :vacation_mode
      t.timestamps null: false
    end
  end
end
