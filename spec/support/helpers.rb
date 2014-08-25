module Helpers

  # Used to mimic the same method available in feature testing
  # ex.
  #   rendered.within('section#header') do |header|
  #     header.should have_link 'Log Out'
  #   end
  # String.class_eval used instead of class String because the latter loads this as a constant, not a method!
  # Some insight to difference here: http://stackoverflow.com/a/10339348/2197402
  String.class_eval do
    def within(selector)
      # https://github.com/jnicklas/capybara/issues/384#issuecomment-1667712
      Capybara.string(self).find(selector).tap do |selection|
        yield selection
      end
    end
  end

  def view_spec_page
    require 'launchy'
    filename = "tmp/view_spec_render-#{Time.now.to_i}.html"
    File.open(filename, 'w') { |file| file.write(rendered) }
    Launchy.open filename
  rescue LoadError
    warn 'Sorry, you need to install launchy to open pages: `gem install launchy`'
  end

  def valid_attributes_hookup
    { title: 'one time event',
      start_date: '2020-07-17',
      start_time: '09:00',
      duration: 60,
    }.as_json
  end

  def invalid_attributes_hookup
    { start_time: '09:00',
      duration: 60,
    }.as_json
  end
end

RSpec::Matchers.define :have_default_cc_addresses do
  match do |mail|
    mail.cc && (mail.cc.include? 'support@agileventures.org')
  end
end
