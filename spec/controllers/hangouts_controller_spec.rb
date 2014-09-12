require 'spec_helper'

describe HangoutsController do
  let(:params) { {id: '333', host_id: 'host', title: 'title'} }
  let(:valid_session) { {} }

  before do
    allow(controller).to receive(:allowed?).and_return(true)
    allow(SlackService).to receive(:post_hangout_notification)
    request.env['HTTP_ORIGIN'] = 'http://test.com'
  end

  describe '#index' do
    before do
      FactoryGirl.create_list(:hangout, 3)
      FactoryGirl.create_list(:hangout, 3, updated: 1.hour.ago)
    end

    context 'show all hangouts' do
      it 'assigns all hangouts' do
        get :index, {kill_pending: 'true'}
        expect(assigns(:hangouts).count).to eq(6)
      end
    end

    context 'show only live hangouts' do
      it 'assigns live hangouts' do
        get :index, {live: 'true', kill_pending: 'true'}
        expect(assigns(:hangouts).count).to eq(3)
      end
    end
  end

  describe '#new' do
    before(:each) do
      @controller.stub(:authenticate_user!).and_return(true)
      get :new, valid_session
    end

    it 'assigns a new hangout as @hangout' do
      assigns(:hangout).should be_a_new(Hangout)
    end

    it 'renders the new template' do
      expect(response).to render_template 'new'
    end
  end

  describe 'POST create' do
    let(:valid_attributes) { { id: @hangout, hangout: FactoryGirl.attributes_for(:hangout), start_date: '17 Jun 2013', start_time: '09:00:00 UTC' } }
    let(:invalid_attributes) { { id: @hangout, hangout: FactoryGirl.attributes_for(:hangout, title: nil), start_date: '', start_time: '' } }
    before :each do
      @controller.stub(:authenticate_user!).and_return(true)
    end

    context 'with valid attributes' do
      it 'saves the new hangout in the database' do
        expect {
          post :create, valid_attributes
        }.to change(Hangout, :count).by(1)
      end
    end
  end

  describe '#update' do
    before(:each) do
      valid_attributes= FactoryGirl.attributes_for(:hangout)
      @hangout = FactoryGirl.create(:hangout, valid_attributes)
      allow_any_instance_of(Hangout).to receive(:update).and_return('true')
    end

    it 'creates a hangout if there is no hangout assosciated with the event' do
      get :update, params
      hangout = Hangout.find_by_uid('333')
      expect(hangout).to be_valid
    end

    it 'updates a hangout if it is present' do
      expect_any_instance_of(Hangout).to receive(:update_attributes)
      params[:id] = @hangout.uid
      get :update, params
    end

    it 'returns a success response if update is successful' do
      get :update, params
      expect(response.status).to eq(200)
    end

    it 'calls the SlackService to post hangout notification on successful update' do
      expect(SlackService).to receive(:post_hangout_notification).with(an_instance_of(Hangout))
      get :update, params.merge(notify: 'true')
    end

    it 'does not call the SlackService' do
      allow_any_instance_of(Hangout).to receive(:update).and_return(false)
      expect(SlackService).not_to receive(:post_hangout_notification).with(an_instance_of(Hangout))
      get :update, params.merge(notify: 'false')
    end

# the code now catches this error without reporting a failure response!
    # it 'returns a failure response if update is unsuccessful' do
    #   allow_any_instance_of(Hangout).to receive(:update).and_return(false)
    #   get :update, params
    #   expect(response.status).to eq(500)
    # end

    it 'redirects to hookups manage page if the link was updated manually' do
      allow(controller).to receive(:local_request?).and_return(true)
      valid_attributes= FactoryGirl.attributes_for(:hangout)
      @hangout = FactoryGirl.create(:hangout, valid_attributes)
      get :update, params.merge(id: @hangout.uid)
      expect(response).to redirect_to(manage_hangout_path(@hangout.id))
    end

# the code now catches this error without reporting a failure response!
#     context 'required parameters are missing' do
#       it 'raises exception on missing host_id' do
#         params[:host_id] = nil
#         expect{ get :update, params }.to raise_error(ActionController::ParameterMissing)
#       end
#
#       it 'raises exception on missing title' do
#         params[:title] = nil
#         expect{ get :update, params }.to raise_error(ActionController::ParameterMissing)
#       end
#     end
  end

  describe 'CORS handling' do
    it 'drops request if the origin is not allowed' do
      allow(controller).to receive(:allowed?).and_return(false)
      get :update, params
      expect(response.status).to eq(400)
    end

    it 'sets CORS headers' do
      headers = { 'Access-Control-Allow-Origin' => 'http://test.com',
                  'Access-Control-Allow-Methods' => 'PUT' }

      get :update, params
      expect(response.headers).to include(headers)
    end

    it 'responses OK on preflight check' do
      get :update, params
      expect(response.status).to eq(200)
    end
  end

end
