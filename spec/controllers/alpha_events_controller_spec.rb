require 'spec_helper'

describe AlphaEventsController do 

  describe '#index' do
    it "renders index page" do
       get :index
       expect(response).to render_template 'index'
    end

    it "assigns all Alpha Events" do
      2.times { AlphaEvent.create }
      get :index

      expect(assigns(:events).count).to eq(2)
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
end
