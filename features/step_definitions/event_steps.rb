Given(/^I am on Events index page$/) do
  visit events_path
end

Given(/^following events exist:$/) do |table|
  table.hashes.each do |hash|
    Event.create!(hash)
  end
end

Given(/^following events exist with active hangouts:$/) do |table|
  table.hashes.each do |hash|
    event = Event.create!(hash)
    event.hangouts.create(hangout_url: 'x@x.com',
                          updated_at: 1.minute.ago,
                          category: event.category,
                          title: event.name)
  end
end

Given(/^following hangouts exist:$/) do |table|
  table.hashes.each do |hash|
    Hangout.create!(hash)
  end
end

Then(/^I should be on the Events "([^"]*)" page$/) do |page|
  case page.downcase
    when 'index'
      current_path.should eq events_path

    when 'create'
      current_path.should eq events_path
    else
      pending
  end
end

Then(/^I should see multiple "([^"]*)" events$/) do |event|
  #puts Time.now
  page.all(:css, 'a', text: event, visible: false).count.should be > 1
end

When(/^the next event should be in:$/) do |table|
  table.rows.each do |period, interval|
    page.should have_content([period, interval].join(' '))
  end
end

Given(/^I am on the show page for event "([^"]*)"$/) do |name|
  event = Event.find_by_name(name)
  visit event_path(event)
end

Then(/^I should be on the event "([^"]*)" page for "([^"]*)"$/) do |page, name|
  event = Event.find_by_name(name)
  page.downcase!
  case page
    when 'show'
      current_path.should eq event_path(event)
    else
      current_path.should eq eval("#{page}_event_path(event)")
  end
end

Given(/^the date is "([^"]*)"$/) do |jump_date|
  Delorean.time_travel_to(Time.parse(jump_date))
end

When(/^I follow "([^"]*)" for "([^"]*)" "([^"]*)"$/) do |linkid, table_name, hookup_number|
  links = page.all(:css, "table##{table_name} td##{linkid} a")
  link = links[hookup_number.to_i - 1]
  link.click
end


When(/^I am on the new Events index page$/) do
  visit alpha_event_path
end

Given(/^I am on the new page for Event$/) do
  visit alpha_new_event_path
end

When(/^I fill in an event with details:$/) do |table|
  with_scope(name) do
    table.rows.each do |row|
      within('form#event-form') do
        fill_in row[0], with: row[1]
      end
    end
  end
end

Then(/^I should be on the alpha Event "([^"]*)" page$/) do |arg|
    case page.downcase
      when 'index'
        current_path.should eq alpha_events_path

      when 'create'
        current_path.should eq alpha_new_events_path
      else
        pending
    end
end

