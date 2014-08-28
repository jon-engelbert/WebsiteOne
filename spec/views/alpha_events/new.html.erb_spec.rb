require 'spec_helper.rb'
describe "alpha_events/new", type: :view do
  #context "user signed in" do
    it 'should display labels for new event creation' do
      assign(:alpha_event, stub_model(AlphaEvent).as_new_record)
      render
      expect(rendered).to have_text('Title')
    end

    it 'should display fields for new event creation' do
      view.lookup_context.prefixes = %w[alpha_events application]
      assign(:alpha_event, stub_model(AlphaEvent).as_new_record)
      render
      expect(rendered).to have_content('alpha_event_title')
    end
  #end
end