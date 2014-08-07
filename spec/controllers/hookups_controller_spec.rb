require 'spec_helper'

describe HookupsController, type: :controller do
  describe 'add hookup' do
    it 'assigns a pending hookup to the view' do
      event = FactoryGirl.create Event, category: "PairProgramming"
      @hangout = FactoryGirl.create(:hangout,
                                    event_id: event.id)
      allow_any_instance_of(Event).to receive(:last_hangout).and_return(@hangout)
      allow_any_instance_of(Event).to receive(:end_time).and_return(1.hour.from_now)
      get :index
      expect(assigns(:pending_events)[0]).to eq(event)
    end

    it 'assigns an active hookup for the view' do
      @event = FactoryGirl.create Event, category: "PairProgramming"
      @hangout = @event.hangouts.create(hangout_url: 'anything@anything.com',
                                        updated_at: 1.minute.ago,
                                        category: "PairProgramming")
      get :index
      expect(assigns(:active_hangouts)[0]).to eq(@hangout)
    end
  end

  describe 'filter' do
    it 'assigns a pending hookup to the view' do
      event = FactoryGirl.create Event, category: "PairProgramming"
      @hangout = FactoryGirl.create(:hangout,
                                    event_id: event.id)
      allow_any_instance_of(Event).to receive(:last_hangout).and_return(@hangout)
      allow_any_instance_of(Event).to receive(:end_time).and_return(1.hour.from_now)
      get :filter, category: 'hookups'
      expect(assigns(:pending_events)[0]).to eq(event)
    end

    it 'assigns an active hookup for the view' do
      @event = FactoryGirl.create Event, category: "PairProgramming"
      @hangout = @event.hangouts.create(hangout_url: 'anything@anything.com',
                                        updated_at: 1.minute.ago,
                                        category: "PairProgramming")
      get :filter, category: 'hookups'
      expect(assigns(:active_hangouts)[0]).to eq(@hangout)
    end

    it 'assigns a pending scrum to the view' do
      event = FactoryGirl.create Event, category: "scrum"
      @hangout = FactoryGirl.create(:hangout,
                                    event_id: event.id)
      allow_any_instance_of(Event).to receive(:last_hangout).and_return(@hangout)
      allow_any_instance_of(Event).to receive(:end_time).and_return(1.hour.from_now)
      get :filter, category: 'scrums'
      expect(assigns(:pending_events)[0]).to eq(event)
    end

    it 'assigns an active scrum for the view' do
      @event = FactoryGirl.create Event, category: "scrum"
      @hangout = @event.hangouts.create(hangout_url: 'anything@anything.com',
                                        updated_at: 1.minute.ago,
                                        category: "scrum")
      get :filter, category: 'scrums'
      expect(assigns(:active_hangouts)[0]).to eq(@hangout)
    end
  end
end
