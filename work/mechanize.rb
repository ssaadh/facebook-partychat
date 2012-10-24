require 'mechanize'

class Rails
  @root = ''
  class << self
    attr_accessor :root
  end
end

Rails.root = '/Users/whathappened/Projects/Fun Stuff/afriendlysyncingapp'

def login_and_save_cookie( page )
  login_form = page.form_with( :id => 'login_form' )
  
  #@TODO dont have email/password publicly here
  require "#{File.dirname( __FILE__ )}/fb_auth.rb"
  login_form[ 'email' ] = email
  login_form[ 'pass' ] = pass
  page = login_form.submit# 'login'
  #@TODO test to make sure page logged in
  @agent.cookie_jar.save_as( "#{Rails.root}/tmp/fb_cookie.yml" )
  return page
end

@agent = Mechanize.new

cookie_location = "#{Rails.root}/tmp/fb_cookie.yml"
if File.exist? cookie_location
  @agent.cookie_jar.load( "#{Rails.root}/tmp/fb_cookie.yml" )
end

facebook_site = @agent.get( 'http://m.facebook.com/messages' )

current_url = facebook_site.uri.to_s
current_path = URI.parse( current_url ).path

if !current_path.include? 'messages'
  facebook_site = login_and_save_cookie( facebook_site )
end

thread_id = 'THREAD_ID'
individual_thread_url = "https://m.facebook.com/messages/read?action=read&tid=id.#{thread_id}"
individual_thread = @agent.get( individual_thread_url )

content = 'Default text'

reply_form = individual_thread.form_with( :id => 'composer_form' )
reply_form[ 'body' ] = content
reply_form.submit