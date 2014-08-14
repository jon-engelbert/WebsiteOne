require 'spec_helper'

describe EventPresenter do
  let(:presenter){ EventPresenter.new(event_object) }

  context 'all fields are present' do
    let(:event_object){ FactoryGirl.build_stubbed(:event, start_datetime: '11:15') }

    it 'displays created time' do
      expect(presenter.created_at).to eq('11:15')
    end

    it 'displays title' do
      expect(presenter.title).to eq(event_object.name)
    end

    it 'displays category' do
      expect(presenter.category).to eq(event_object.category)
    end

    # it 'displays project' do
    #   expect(presenter.project).to match %Q(<a href="#{project_path(event_object.project)}")
    #   expect(presenter.project).to match "#{event_object.project.title}"
    # end

    it 'displays event' do
      expect(presenter.event).to match %Q(<a href="#{event_path(event_object)}")
      expect(presenter.event).to match "#{event_object.name}"
    end

    # it 'returns host' do
    #   expect(presenter.host).to eq(hangout.host)
    # end

    # it 'returns an array of participants' do
    #   participant = FactoryGirl.create(:user, gplus: hangout.participants.first.last[:person][:id])
    #
    #   expect(presenter.participants.count).to eq(2)
    #   expect(presenter.participants.first).to eq(participant)
    # end

    # it 'returns video url' do
    #   expect(presenter.video_url).to eq("http://www.youtube.com/watch?v=yt_video_id&feature=youtube_gdata")
    # end
  end

  context 'some fields are missing' do
    let(:event_object){ FactoryGirl.build_stubbed(:event,
                                             name: nil,
                                             category: nil
    )}
    it 'displays title' do
      expect(presenter.title).to eq('No title given')
    end

    it 'displays category' do
      expect(presenter.category).to eq('-')
    end
  end

end

