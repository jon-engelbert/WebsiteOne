class AddScheduleToEvent < ActiveRecord::Migration
  include IceCube
  def up
    add_column :events, :schedule_yaml, :text
    Event.reset_column_information
    Event.all.each do |event|
      if event.repeats != 'never'
        if (event.repeat_ends)
          schedule = Schedule.new(event.start_datetime, end_time: event.repeat_ends_on)
        else
          schedule = Schedule.new(event.start_datetime)
        end
        days = event.repeats_weekly_each_days_of_the_week.map { |d| d.to_sym }
        schedule.add_recurrence_rule IceCube::Rule.weekly(event.repeats_every_n_weeks).day(*days)
        event.schedule_yaml = schedule.to_yaml
        event.save
      end
    end
    remove_column :events, :repeats
    remove_column :events, :repeat_ends_on
    remove_column :events, :start_datetime
    remove_column :events, :repeats_weekly_each_days_of_the_week_mask
    remove_column :events, :repeats_every_n_weeks
    remove_column :events, :repeat_ends
  end

  def down
    remove_column :events, :schedule_yaml
    add_column :events, :repeats, string
    add_column :events, :repeat_ends, boolean
    add_column :events, :repeat_ends_on, date
    add_column :events, :start_datetime, datetime
    add_column :events, :repeats_weekly_each_days_of_the_week_mask, integer
    add_column :events, :repeats_every_n_weeks, integer
  end
end
