class CreateAlphaEvents < ActiveRecord::Migration
  def change
    create_table :alpha_events do |t|
      t.string :title
      t.datetime :start_planned
      t.string :tags
      t.string :agenda
      t.string :comments

      t.timestamps
    end
    add_index :alpha_events, :title
    add_index :alpha_events, :start_planned
  end
end
