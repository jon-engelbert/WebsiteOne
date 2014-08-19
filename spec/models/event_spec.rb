require 'spec_helper'

describe Event do
  it 'should respond to friendly_id' do
    expect(Event.new).to respond_to(:friendly_id)
  end

  it 'should respond to "schedule" method' do
    Event.respond_to?('schedule')
  end

  it 'return the latest hangout' do
    event = FactoryGirl.create(:event)

    FactoryGirl.create(:hangout, event: event, title: 'first', created: Time.parse('10:00'))
    FactoryGirl.create(:hangout, event: event, title: 'last', created: Time.parse('15:00'))

    expect(event.last_hangout.title).to eq('last')
  end

  context 'return false on invalid inputs' do
    before do
      @event = FactoryGirl.create(:event)
    end
    it 'nil :name' do
      @event.name = ''
      expect(@event.save).to be_falsey
    end

    it 'nil :category' do
      @event.category = nil
      expect(@event.save).to be_falsey
    end

    it 'nil :repeats' do
      @event.repeats = nil
      expect(@event.save).to be_falsey
    end
  end

  context 'should create a scrum event that ' do
    it 'is scheduled for one occasion' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'one time event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'never',
                                        repeats_every_n_weeks: nil,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Mon, 17 Jun 2013',
                                        time_zone: 'Eastern Time (US & Canada)')
      expect(event.schedule.first(5)).to eq(['Mon, 17 Jun 2013 09:00:00 UTC +00:00'])
    end

    it 'is scheduled for every weekend' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'every weekend event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'weekly',
                                        repeats_every_n_weeks: 1,
                                        repeats_weekly_each_days_of_the_week_mask: 96,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Tue, 25 Jun 2013',
                                        time_zone: 'Eastern Time (US & Canada)')
      expect(event.schedule.first(5)).to eq(['Sat, 22 Jun 2013 09:00:00 UTC +00:00', 'Sun, 23 Jun 2013 09:00:00 UTC +00:00', 'Sat, 29 Jun 2013 09:00:00 UTC +00:00', 'Sun, 30 Jun 2013 09:00:00 UTC +00:00', 'Sat, 06 Jul 2013 09:00:00 UTC +00:00'])
    end

    it 'is scheduled for every Sunday' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'every Sunday event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'weekly',
                                        repeats_every_n_weeks: 1,
                                        repeats_weekly_each_days_of_the_week_mask: 64,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Mon, 17 Jun 2013',
                                        time_zone: 'Eastern Time (US & Canada)')
      expect(event.schedule.first(5)).to eq(['Sun, 23 Jun 2013 09:00:00 UTC +00:00', 'Sun, 30 Jun 2013 09:00:00 UTC +00:00', 'Sun, 07 Jul 2013 09:00:00 UTC +00:00', 'Sun, 14 Jul 2013 09:00:00 UTC +00:00', 'Sun, 21 Jul 2013 09:00:00 UTC +00:00'])
    end

    it 'is scheduled for every Monday' do
      event = FactoryGirl.build_stubbed(Event,
                                        name: 'every Monday event',
                                        category: 'Scrum',
                                        description: '',
                                        start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                                        duration: 600,
                                        repeats: 'weekly',
                                        repeats_every_n_weeks: 1,
                                        repeats_weekly_each_days_of_the_week_mask: 1,
                                        repeat_ends: 'never',
                                        repeat_ends_on: 'Mon, 17 Jun 2013',
                                        time_zone: 'UTC')
      expect(event.schedule.first(5)).to eq(['Mon, 17 Jun 2013 09:00:00 GMT +00:00', 'Mon, 24 Jun 2013 09:00:00 GMT +00:00', 'Mon, 01 Jul 2013 09:00:00 GMT +00:00', 'Mon, 08 Jul 2013 09:00:00 GMT +00:00', 'Mon, 15 Jul 2013 09:00:00 GMT +00:00'])
    end

    it 'handles live? requests' do
      @event = FactoryGirl.build_stubbed(Event)
      expect(@event).to respond_to(:live?)
    end
  end

  context 'should create a hookup event that' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'PP Monday event',
                                         category: 'PairProgramming',
                                         start_datetime: 'Mon, 17 Jun 2014 09:00:00 UTC',
                                         duration: 90,
                                         repeats: 'never',
                                         time_zone: 'UTC')
    end

    it 'should expire events that ended' do
      hangout = @event.hangouts.create(hangout_url: 'http://hangout.test',
                                       updated_at: '2014-06-17 10:25:00 UTC')
      allow(hangout).to receive(:started?).and_return(true)
      Delorean.time_travel_to(Time.parse('2014-06-17 10:31:00 UTC'))
      expect(@event.live?).to be_falsey
    end

    it 'should mark as active events which have started and have not ended' do
      hangout = @event.hangouts.create(hangout_url: 'http://hangout.test',
                                       updated_at: '2014-06-17 10:25:00 UTC')
      Delorean.time_travel_to(Time.parse('2014-06-17 10:26:00 UTC'))
      expect(@event.live?).to be_truthy
    end

    it 'should not be started if events have not started' do
      hangout = @event.hangouts.create(hangout_url: nil,
                                       updated_at: nil)
      Delorean.time_travel_to(Time.parse('2014-06-17 9:30:00 UTC'))
      expect(@event.live?).to be_falsey
    end
  end

  context 'should create a hookup event that' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'PP Monday event',
                                         category: 'PairProgramming',
                                         start_datetime: 'Mon, 17 Jun 2014 09:00:00 UTC',
                                         duration: 90,
                                         repeats: 'never',
                                         time_zone: 'UTC')
    end

    it 'should expire events that ended' do
      hangout = @event.hangouts.create(hangout_url: 'http://hangout.test',
                                       updated_at: '2014-06-17 10:25:00 UTC')
      allow(hangout).to receive(:started?).and_return(true)
      Delorean.time_travel_to(Time.parse('2014-06-17 10:31:00 UTC'))
      expect(@event.live?).to be_falsey
    end

    it 'should mark as active events which have started and have not ended' do
      hangout = @event.hangouts.create(hangout_url: 'http://hangout.test',
                                       updated_at: '2014-06-17 10:25:00 UTC')
      Delorean.time_travel_to(Time.parse('2014-06-17 10:26:00 UTC'))
      expect(@event.live?).to be_truthy
    end

    it 'should not be started if events have not started' do
      hangout = @event.hangouts.create(hangout_url: nil,
                                       updated_at: nil)
      Delorean.time_travel_to(Time.parse('2014-06-17 9:30:00 UTC'))
      expect(@event.live?).to be_falsey
    end
  end

  context 'Event url' do
    before (:each) do
      @event = {name: 'one time event',
                category: 'Scrum',
                description: '',
                start_datetime: 'Mon, 17 Jun 2013 09:00:00 UTC',
                duration: 600,
                repeats: 'never',
                repeats_every_n_weeks: nil,
                repeat_ends: 'never',
                repeat_ends_on: 'Mon, 17 Jun 2013',
                time_zone: 'Eastern Time (US & Canada)'}
    end

    it 'should be set if valid' do
      event = Event.create!(@event.merge(:url => 'http://google.com'))
      expect(event.save).to be_truthy
    end

    it 'should be rejected if invalid' do
      event = Event.create(@event.merge(:url => 'http:google.com'))
      expect(event.errors[:url].size).to eq(1)
    end
  end

  describe 'Event#next_occurences' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'Spec Scrum',
                                         start_datetime: '2014-03-07 10:30:00 UTC',
                                         duration: 30)

      allow(@event).to receive(:repeats).and_return('weekly')
      allow(@event).to receive(:repeats_every_n_weeks).and_return(1)
      allow(@event).to receive(:repeats_weekly_each_days_of_the_week_mask).and_return(0b1111111)
      allow(@event).to receive(:repeat_ends).and_return(true)
      allow(@event).to receive(:repeat_ends_on).and_return('Tue, 25 Jun 2015')
      allow(@event).to receive(:friendly_id).and_return('spec-scrum')
    end

    it 'should return the next occurence of the event' do
      Delorean.time_travel_to(Time.parse('2014-03-07 09:27:00 UTC'))
      expect(@event.next_occurrence_time_method).to eq(Time.parse('2014-03-07 10:30:00 UTC'))
    end

    it 'includes the event that has been started within the last 30 minutes' do
      Delorean.time_travel_to(Time.parse('2014-03-07 10:50:00 UTC'))
      expect(@event.next_occurrence_time_method).to eq(Time.parse('2014-03-07 10:30:00 UTC'))
    end

    it 'does not include the event that has been started within more than 30 minutes ago' do
      options = {}
      Delorean.time_travel_to(Time.parse('2014-03-07 11:01:00 UTC'))
      expect(@event.next_occurrence_time_method).to eq(Time.parse('2014-03-08 10:30:00 UTC'))
    end

    context 'test against start_datetime and repeat_ends_on' do
      it 'starts in the future' do
        Delorean.time_travel_to(Time.parse('2014-03-01 09:27:00 UTC'))
        expect(@event.next_occurrence_time_method).to eq(Time.parse('2014-03-07 10:30:00 UTC'))
      end

      it 'already ended in the past' do
        Delorean.time_travel_to(Time.parse('2016-02-07 09:27:00 UTC'))
        expect(@event.next_occurrences.count).to eq(0)
      end
    end

    context 'with input arguments' do
      context ':limit option' do

        it 'should limit the size of the output' do
          options = { limit: 2 }
          Delorean.time_travel_to(Time.parse('2014-03-08 09:27:00 UTC'))
          expect(@event.next_occurrences(options).count).to eq(2)
        end
      end

      context ':start_time option' do
        it 'should return only occurrences after a specific time' do
          options = {start_time: Time.parse('2014-03-09 9:27:00 UTC')}
          Delorean.time_travel_to(Time.parse('2014-03-05 09:27:00 UTC'))
          expect(@event.next_occurrence_time_method(options)).to eq(Time.parse('2014-03-09 10:30:00 UTC'))
        end
      end
    end
  end

  describe 'Event#start_datetime_for_collection for starting event' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'Spec Scrum never ends',
                                         start_datetime: '2014-03-07 10:30:00 UTC',
                                         duration: 30)
    end

    it 'should return the start_time if it is specified' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      options = {start_time: '2015-06-20 09:27:00 UTC'}
      expect(@event.start_datetime_for_collection(options)).to eq(options[:start_time])
    end

    it 'should return 30 minutes before now if start_time is not specified' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      expect(@event.start_datetime_for_collection.to_datetime.to_s).to eq((Time.now - Event.CollectionTimePast).utc.to_datetime.to_s)
    end

    it 'should return 60 minutes before now if start_time is not specified and CollectionTimePast=60' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      Event.CollectionTimePast=60
      expect(@event.start_datetime_for_collection.to_datetime.to_s).to eq((Time.now - Event.CollectionTimePast).utc.to_datetime.to_s)
    end
  end

  describe 'Event#final_datetime_for_collection for repeating event with ends_on' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'Spec Scrum ends',
                                         start_datetime: '2014-03-07 10:30:00 UTC',
                                         repeats: 'weekly',
                                         repeats_every_n_weeks: 1,
                                         repeats_weekly_each_days_of_the_week_mask: 0b1111111,
                                         repeat_ends: true,
                                         repeat_ends_on: '2015-6-25')
    end

    it 'should return the repeat_ends_on datetime if that comes first' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      options = {end_time: '2015-06-30 09:27:00 UTC'}
      expect(@event.final_datetime_for_collection(options)).to eq(@event.repeat_ends_on.to_datetime)
    end

    it 'should return the options[:endtime] if that comes before repeat_ends_on' do
      Delorean.time_travel_to(Time.parse('2015-06-15 09:27:00 UTC'))
      options = {end_time: '2015-06-20 09:27:00 UTC'}
      expect(@event.final_datetime_for_collection(options)).to eq(options[:end_time].to_datetime)
    end

    it 'should return the repeat_ends_on datetime if there is no options[end_time] and the ends_on datetime is less than 10 days away' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      expect(@event.final_datetime_for_collection).to eq(@event.repeat_ends_on.to_datetime)
    end
  end

  describe 'Event#final_datetime_for_display for never-ending event' do
    before do
      @event = FactoryGirl.build_stubbed(Event,
                                         name: 'Spec Scrum never-ending',
                                         start_datetime: '2014-03-07 10:30:00 UTC',
                                         repeats: 'weekly',
                                         repeats_every_n_weeks: 1,
                                         repeats_weekly_each_days_of_the_week_mask: 0b1111111,
                                         repeat_ends: false)
    end

    it 'should return the options[:endtime] when specified' do
      Delorean.time_travel_to(Time.parse('2015-06-15 09:27:00 UTC'))
      options = {end_time: '2015-06-20 09:27:00 UTC'}
      expect(@event.final_datetime_for_collection(options)).to eq(options[:end_time].to_datetime)
    end

    it 'should return 10 days from now if there is no options[end_time]' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      Event.CollectionTimeFuture= 10.days   # 10 days is the default
      expect(@event.final_datetime_for_collection().to_datetime.to_s).to eq(10.days.from_now.to_datetime.to_s)
    end

    it 'should return 3 days from now if there is no options[end_time] and COLLECTION_TIME_FUTURE is 3.days instead of 10.days' do
      Delorean.time_travel_to(Time.parse('2015-06-23 09:27:00 UTC'))
      Event.CollectionTimeFuture= 3.days
      expect(@event.final_datetime_for_collection().to_datetime.to_s).to eq(3.days.from_now.to_datetime.to_s)
    end
  end

  describe 'Event.next_event_occurence' do
    let(:event) do
      Event.new(
          name: 'Spec Scrum',
          start_datetime: '2014-03-07 10:30:00 UTC',
          category: 'Scrum',
          duration: 30,
          repeats: 'never',
          repeat_ends: true,
          repeat_ends_on: '')
    end

    before(:each) do
      Event.stub(:exists?).and_return true
      Event.stub(:where).and_return [ event ]
    end

    it 'should return the next event occurence' do
      Delorean.time_travel_to(Time.parse('2014-03-07 09:27:00 UTC'))
      expect(Event.next_event_occurrence).to eq event
    end

    it 'should have a 30 minute buffer' do
      Event.CollectionTimePast=30.minutes   #30 minutes is the default
      Delorean.time_travel_to(Time.parse('2014-03-07 10:59:59 UTC'))
      expect(Event.next_event_occurrence).to eq event
    end

    it 'should not return events that were scheduled to start more than 30 minutes ago' do
      Event.CollectionTimePast=30.minutes   #30 minutes is the default
      Delorean.time_travel_to(Time.parse('2014-03-07 11:01:00 UTC'))
      expect(Event.next_event_occurrence).to be_nil
    end
  end
end
