require 'spec_helper'

describe 'alpha_events/index', type: :view do
  it "renders main attributes" do
    render
    expect(rendered).to have_text('event name')
  end
end
