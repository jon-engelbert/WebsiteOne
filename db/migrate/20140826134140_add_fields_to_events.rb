class AddFieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :start_planned, :datetime
    add_column :events, :tags, :string
    add_column :events, :agenda, :string
    add_column :events, :comments, :string
    add_index :events, :start_planned
  end
end
