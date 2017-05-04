class CreateReportedYogaSessions < ActiveRecord::Migration
  def change
    create_table :reported_yoga_sessions do |t|
      t.belongs_to :teacher, index: true
      t.belongs_to :student, index: true
      t.belongs_to :yoga_session, index: true
      t.string :description
      t.timestamps null: false
    end
  end
end
