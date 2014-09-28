require 'spec_helper'

describe VisitorsController do
  let(:valid_params){ {name: 'Ivan', email: 'my@email.com', message: 'Love your site!'} }
  it 'renders index template' do
    get :index
    expect(response).to render_template('index')
  end

  it 'assigns event to next_occurrence' do
    event_instance = FactoryGirl.create(:event_instance)
    Event.should_receive(:next_event_instance).with(:Scrum).and_return(event_instance)
    get :index
    expect(assigns(:event_instance)).to eq event_instance
  end
end
