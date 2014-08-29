When(/^I fill in an alpha event:$/) do |table|
  with_scope(name) do
    table.rows.each do |row|
      within('form#alpha-event-form') do
        fill_in row[0], with: row[1]
      end
    end
  end
end

Given(/^following alpha_event exist:$/) do |table|
  table.hashes.each do |hash|
    AlphaEvent.create!(hash)
  end
end

When(/^I click the Show link for the first alpha event$/) do
  first(:link,'Show').click
end

When(/^I click the Edit link for the first alpha event$/) do
  find_link('Edit', :first).click
  # row = page.find(:id, "row-1}")
  # within row do
  #   link = row.find(:xpath, text: 'Edit')
  #   link.click
  # end
end

