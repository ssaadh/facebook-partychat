require 'sinatra'
set :protection, except: :ip_spoofing

require 'sinatra/activerecord'
require_relative 'config/environments'
require_relative 'models'

helpers do
  def login_and_save_cookie( page )
    cookie_location = './tmp/fb_cookie.yml'
    
    login_form = page.form_with( :id => 'login_form' )
    
    #@TODO dont have email/password publicly here
    login_form[ 'email' ] = ENV[ 'fb_user' ]
    login_form[ 'pass' ] = ENV[ 'fb_pass' ]
    page = login_form.submit# 'login'
    #@TODO test to make sure page logged in
    if File.exist? cookie_location
      File.delete cookie_location
    end
    @agent.cookie_jar.save_as( cookie_location )
    return page
  end
end

post '/api/fb/pull/:thread' do
  thread_nickname = params[ :thread ]
  
  # Parameter from post request
  instant_message_body = params[ :body ]
  
  # This is how the Partychat hook sends data. Not good for us so have to parse it
  instant_message_extraction = instant_message_body.match( /^\[(?<from>\S+)\] \/[\S]+ (?<body>.+)/ )
  sender_object = FbMember.find_by_google_talk_name( instant_message_extraction[ :from ] )
  send_to_facebook_content = "*#{sender_object.name}:* #{instant_message_extraction[ :body ]}"
  
  # Posting to Facebook
    
  require 'mechanize'
  @agent = Mechanize.new
    
  cookie_location = './tmp/fb_cookie.yml'
  if File.exist? cookie_location
    @agent.cookie_jar.load( './tmp/fb_cookie.yml' )
  end
  
  facebook_site = @agent.get( 'http://m.facebook.com/messages' )
  
  # Check to see if url has redirected to login page
  # If redirected, then it means not logged in  
  current_url = facebook_site.uri.to_s
  current_path = URI.parse( current_url ).path
  
  # Log in and get fresh cookie if having to login again
  if !current_path.include? 'messages'
    #@TODO check to see if actually logged in, otherwise log/report the problem and stop code
    facebook_site = login_and_save_cookie( facebook_site )
  end
  
  # Find the thread name parameter from url in database and go to the thread
  thread_object = FbThread.find_with_receive_endpoint( thread_nickname )
  if thread_object.nil?
    return
  end
  
  thread_id = thread_object.fb_id
  
  # @TODO This is shameful, lol. One of the threads has different api and actual url ids. But current database table only supports one id number. So this is a quick hack for fixing the one thread that has a problem. This definitely needs to be changed by having a second column for the id and be for all columns instead of a hack for one
  if thread_object.id == 5
    thread_id = ENV[ 'fb_thread_id' ]
  end
  individual_thread_url = "https://m.facebook.com/messages/read?action=read&tid=id.#{thread_id}"
  individual_thread = @agent.get( individual_thread_url )
  
  # Post to the message text area on specific thread page
  reply_form = individual_thread.form_with( :id => 'composer_form' )
  reply_form[ 'body' ] = send_to_facebook_content
  reply_form.submit
end

get '/api/fb/push/threads' do
  require 'koala'
  me = Koala::Facebook::API.new( ENV[ 'fb_api' ] )
    
  total_sent_messages_count = 0
  # Get all the threads and latest messages at once for account to save time from polling FB API for each thread
  threads = me.get_object( "me/inbox?&since=#{Time.now.to_i - 500}" )
  threads.each do |single_thread|
    # Skip the current thread if it isn't the database - meaning it doesn't need pushing
    @fb_thread_from_database = FbThread.find_by_fb_id( single_thread[ 'id' ] )
    if @fb_thread_from_database.nil?
      next
    end
        
    thread_sent_messages_count = 0
    # Initializing
    current_message_id = 0    
    # Only take in the hash part for [recent] messages
    last_25_messages = single_thread[ 'comments' ][ 'data' ]
    last_25_messages.each do |message_hash|
      # Need to have message_id work outside this loop so the final one can update the latest message id column in database
      # All the numbers before the underscore are just the thread id the message is in
      current_message_id = message_hash[ 'id' ].sub( /^\d+_/, '' ).to_i
      
      # FB bumps each new message id in a thread up by one.
      # So if the last message id from database is greater aka happened after the current message id you're looking at, skip it
      # This could more stable/future-proof if the checking was switched to the timestamp FB provides
      if @fb_thread_from_database.last_message_id >= current_message_id
        next
      end
      
      # Get who sent the message
      sender = message_hash[ 'from' ][ 'id' ]      
      sender = FbMember.find_by_fb_id( sender )
      
      if sender.is_bot == true
        next
      end
      
      message = message_hash[ 'message' ]
      
      message_from_facebook_to_partychat( @fb_thread_from_database.post_http_endpoint, sender.name, message )
      thread_sent_messages_count += 1
    end
      
    # Update the database with the last message id that was pushed for the thread
    if current_message_id != @fb_thread_from_database.last_message_id
      @fb_thread_from_database.update_column( 'last_message_id', current_message_id )
    end
    "Done with #{@fb_thread_from_database.nickname} and sent #{thread_sent_messages_count} messages"
    total_sent_messages_count += thread_sent_messages_count
  end
  "Sent #{total_sent_messages_count} messages"
end

helpers do
  def message_from_facebook_to_partychat( http_endpoint, sender, message )
    ##
    # Posting to Partychat or well any url that is a post hook
    ##        
    require 'uri'
    require 'net/http'
        
    params = { 'person' => sender, 'message' => message }
        
    Net::HTTP.post_form( URI.parse( http_endpoint ), params )
  end
end

# Eh
get '/' do
  'Nup'
end
