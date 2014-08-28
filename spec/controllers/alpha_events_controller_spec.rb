require 'spec_helper'

describe AlphaEventsController, type: :controller do

  describe '#index' do
    it "renders index page" do
       get :index
       expect(response).to render_template 'index'
    end

    it "assigns all Alpha Events" do
      2.times { AlphaEvent.create }
      get :index
      expect(assigns(:alphaEvents).count).to eq(2)
    end

    #  double( start_planned: '25/08/14 10:00',
    #                 title: 'event 1',
    #                 tags: 'websiteone, pp, ruby',
    #                 agenda: 'Refactor index spec',
    #                 comments: 'Bring your own laptop' )
    #
    # event2= double( start_planned: '10/09/14 16:45',
    #                   title: 'event 2',
    #                   tags: 'autograder, client, deploy',
    #                   agenda: 'finish the rag feature',
    #                   comments: 'Show the client the latest UI' )
  end

  describe 'GET new' do

    before(:each) do
      assign(:alpha_event, stub_model(AlphaEvent, title: "Event Title").as_new_record)
      @controller.stub(:authenticate_user!).and_return(true)
      get :new, valid_session
    end

    it 'assigns a new event as @alpha_event' do
      assigns(:alpha_event).should be_a_new(AlphaEvent)
    end

    it 'renders the new template' do
      expect(response).to render_template 'new'
    end
  end

  describe 'POST create' do
    let(:valid_attributes) {{alpha_events:{ start_planned: '25/08/14 10:00', title: 'event 1', tags: 'websiteone, pp, ruby', agenda: 'Refactor index spec', comments: 'Bring your own laptop'}}}

    before :each do
      @controller.stub(:authenticate_user!).and_return(true)
    end

    context 'with valid attributes' do
      it 'saves the new alpha_event in the database' do
        expect {
          post :create, valid_attributes
        }.to change(AlphaEvent, :count).by(1)
      end

      it 'redirects to alpha_events#index' do
        post :create, valid_attributes
        expect(response).to redirect_to alpha_event_path
      end
    end

    # context 'with invalid attributes' do
    #   it 'does not save the new subject in the database' do
    #     expect {
    #       post :create, invalid_attributes
    #     }.to_not change(Event, :count)
    #     expect(assigns(:event)).to be_a_new(Event)
    #     expect(assigns(:event)).not_to be_persisted
    #   end
    #
    #   it 're-renders the events#new template' do
    #     Event.any_instance.stub(:save).and_return(false)
    #     post :create, event: FactoryGirl.attributes_for(:event, name: nil)
    #     expect(response).to render_template :new
    #   end
    # end
  end
end
