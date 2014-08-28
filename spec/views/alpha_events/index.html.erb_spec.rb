require 'spec_helper'

describe 'alpha_events/index', type: :view do
  before(:each) do
    event1= double(start_planned: '25/08/14 10:00',
                   title: 'event 1',
                   tags: 'websiteone, pp, ruby',
                   agenda: 'Refactor index spec',
                   comments: 'Bring your own laptop')
    event2= double(start_planned: '10/09/14 16:45',
                   title: 'event 2',
                   tags: 'autograder, client, deploy',
                   agenda: 'finish the rag feature',
                   comments: 'Show the client the latest UI')
    @alphaEvents = [event1, event2]
  end

  it "renders main attributes" do
    render
    expect(rendered).to have_text('Title')
    expect(rendered).to have_text('event 1')
    expect(rendered).to have_text('event 2')
  end

  context 'user signed in' do
    before do
      allow(view).to receive(:user_signed_in?).and_return(true)
    end

    it 'renders a create new event button' do
      render
      expect(rendered).to have_css %Q{a[href="#{new_alpha_event_path}"]}, visible: true
    end
  end

  context 'user not signed in' do
    before do
      allow(view).to receive(:user_signed_in?).and_return(false)
    end

    it 'renders a create new event button' do
      render
      expect(rendered).not_to have_css %Q{a[href="#{new_alpha_event_path}"]}, visible: true
    end
  end
end
