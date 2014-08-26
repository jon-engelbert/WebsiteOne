require 'spec_helper'

describe 'alpha_events/index', type: :view do
  it "renders main attributes" do
    event1= double( start_planned: '25/08/14 10:00',
              title: 'event 1',
              tags: 'websiteone, pp, ruby',
              agenda: 'Refactor index spec',
              comments: 'Bring your own laptop' )
    event2= double( start_planned: '10/09/14 16:45',
              title: 'event 2',
              tags: 'autograder, client, deploy',
              agenda: 'finish the rag feature',
              comments: 'Show the client the latest UI' )
    @alphaEvents = [event1, event2]
    render
    expect(rendered).to have_text('Title')
  end
end
