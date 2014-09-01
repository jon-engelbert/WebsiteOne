class AddEventparamsToHangout < ActiveRecord::Migration
  def change
    add_column :hangouts, :start_planned, :datetime
    add_column :hangouts, :description, :string
    add_column :hangouts, :duration_planned, :datetime
  end
end
