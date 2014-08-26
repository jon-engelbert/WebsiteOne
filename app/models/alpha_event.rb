class AlphaEvent < ActiveRecord::Base
  def url_for_me(action)
    if action == 'show'
      "/articles/#{self.to_param}"
    else
      "/articles/#{self.to_param}/#{action}"
    end
  end
end
