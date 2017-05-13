class CreateUserMessages < ActiveRecord::Migration
  def change
    create_table :user_messages do |t|
      t.belongs_to :user, index: true
      t.string :email
      t.string :subject
      t.string :message
      t.timestamps null: false
    end
  end
end
