class AddEventParamsToHangout < ActiveRecord::Migration
  def change
    add_column :hangouts, :start_planned, :datetime
    add_column :hangouts, :description, :string
    add_column :hangouts, :duration_planned, :integer
    add_column :hangouts, :start_gh, :datetime  # this is the start of the google hangout
    add_column :hangouts, :heartbeat_gh, :datetime  # this is the time of the most recent heartbeat of the google hangout
  end
end
