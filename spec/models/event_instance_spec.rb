require 'spec_helper'

describe EventInstance, type: :model do
  let(:hangout) { FactoryGirl.create(:event_instance, updated: '10:00 UTC', hangout_url: nil) }

  context 'hangout_url is not present' do
    before do
      allow(Time).to receive(:now).and_return(Time.parse('01:00 UTC'))
    end

    it '#started? returns falsey' do
      expect(hangout.started?).to be_falsey
    end

    it '#live? returns false' do
      expect(hangout.live?).to be_falsey
    end
  end

  context 'hangout_url is present' do
    before { hangout.hangout_url = 'test' }

    it 'reports live if the link is not older than 5 minutes' do
      allow(Time).to receive(:now).and_return(Time.mktime('10:04:59'))
      expect(hangout.live?).to be_truthy
    end

    it 'reports not live if the link is older than 5 minutes' do
      allow(Time).to receive(:now).and_return(Time.parse('10:05:01 UTC'))
      expect(hangout.live?).to be_falsey
    end
  end

  context 'generate_hangout_id' do
    it 'generates valid hangout_id with project_id' do
      project_id = 0
      allow(Time).to receive(:now).and_return('12345')
      user = FactoryGirl.build_stubbed(:user,
                                       id: 9)
      hangout_id = EventInstance.generate_hangout_id(user, project_id)
      expect(hangout_id).to eq("9012345")
    end
    it 'generates valid hangout_id without project_id' do
      allow(Time).to receive(:now).and_return('12345')
      user = FactoryGirl.build_stubbed(:user,
                                       id: 9)
      hangout_id = EventInstance.generate_hangout_id(user)
      expect(hangout_id).to eq("90012345")
    end
  end
end
