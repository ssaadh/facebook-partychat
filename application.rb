require 'sinatra'
set :protection, except: :ip_spoofing

require 'sinatra/activerecord'
set :database, 'sqlite3:///db/development.sqlite3'
require_relative 'models.rb'

helpers do
  def login_and_save_cookie( page )
    login_form = page.form_with( :id => 'login_form' )
    
    #@TODO dont have email/password publicly here
    require "#{File.dirname( __FILE__ )}/fb_auth.rb"
    login_form[ 'email' ] = ENV[ 'fb_user' ]
    login_form[ 'pass' ] = ENV[ 'fb_pass' ]
    page = login_form.submit# 'login'
    #@TODO test to make sure page logged in
    @agent.cookie_jar.save_as( './tmp/fb_cookie.yml' )
    return page
  end
end

post '/api/fb/pull/:thread' do  
  thread_id = params[ :thread ]
  @from = params[ :from ]
    
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
    
  thread_id = FbThread.find_by_nickname( thread_id )
  individual_thread_url = "https://m.facebook.com/messages/read?action=read&tid=id.#{thread_id}"
  individual_thread = @agent.get( individual_thread_url )
    
  instant_message_body = params[ :body ]
    
  instant_message_extraction = instant_message_body.match( /^\[(?<from>\S+)\] \/[\S]+ (?<body>.+)/ )    
  send_to_facebook_content = "*#{instant_message_extraction[ :from ]}:* #{instant_message_extraction[ :body ]}"
    
  reply_form = individual_thread.form_with( :id => 'composer_form' )
  reply_form[ 'body' ] = content
  reply_form.submit
end

get '/api/fb/push/threads' do
  me = Koala::Facebook::API.new( ENV[ 'fb_api' ] )
    
  # Get all the threads and latest messages at once for account to save time from polling FB API for each thread
  threads = me.get_object( 'me/inbox' )
    
  @threads = ''
  threads.each do |single_thread|
      
    # Skip the current thread if it isn't the database - meaning it doesn't need pushing
    @fb_thread_from_database = FbThread.find_by_fb_id( single_thread[ 'id' ] )
    if @fb_thread_from_database.nil?
      next
    end
      
    # Only take in the hash part for [recent] messages
    last_25_messages = single_thread[ 'comments' ][ 'data' ]
    last_25_messages.each do |message_hash|
      # Need to have message_id work outside this loop so the final one can update the latest message id column in database
      @message_id = message_hash[ 'id' ].sub( /#{message_hash[ 'id' ]}_/, '' ).to_i
        
      # FB bumps each new message id in a thread up by one.
      # So if the last message id from database is greater aka happened after the current message id you're looking at, skip it
      # This could more stable/future-proof if the checking was switched to the timestamp FB provides
      if @fb_thread_from_database.last_message_id >= @message_id
        next
      end
        
      # Get who sent the message
      sender = message_hash[ 'from' ][ 'id' ]
      sender = FbMember.find_by_fb_id( sender )
        
      #sent_time = message_hash[ 'created_time' ].to_time.in_time_zone( 'Eastern Time (US & Canada)' ).strftime( '%I:%M %p' )
                
      message = message_hash[ 'message' ]
                
      ##
      # Posting to Partychat or well any url that is a post hook
      ##        
      require 'uri'
      require 'net/http'
        
      params = { 'person' => sender.name, 'message' => message }
        
      Net::HTTP.post_form( URI.parse( @fb_thread_from_database.post_http_endpoint ), params )
    end
      
    # Update the database with the last message id that was pushed for the thread
    @fb_thread_from_database.update_column( 'last_message_id', @message_id )
      
  end
end

# Eh
get '/' do
  'Nup.'
end