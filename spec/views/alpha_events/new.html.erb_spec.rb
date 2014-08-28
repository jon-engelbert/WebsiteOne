require 'spec_helper.rb'
describe "alpha_events/new", type: :view do
    it 'should display labels for new event creation' do
      assign(:alpha_event, stub_model(AlphaEvent).as_new_record)
      render
      expect(rendered).to have_text('Title')
    end

    it 'should display fields for new event creation' do
      assign(:alpha_event, stub_model(AlphaEvent, title: "Event Title").as_new_record)
      render
      expect(rendered).to have_text('Event Title')
    end
end
