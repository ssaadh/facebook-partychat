require 'sinatra'
set :protection, except: :ip_spoofing

require 'sinatra/activerecord'
require_relative 'config/environments'
require_relative 'models'

post '/api/fb/pull/:thread' do
  thread_nickname = params[ :thread ]
  
  # Parameter from post request
  instant_message_body = params[ :body ]
  
  # This is how the Partychat hook sends data. Not good for us so have to parse it
  instant_message_extraction = instant_message_body.match( /^\[(?<from>\S+)\] \/[\S]+ (?<body>.+)/ )
  sender_object = FbMember.find_by_google_talk_name( instant_message_extraction[ :from ] )
  send_to_facebook_content = "*#{sender_object.name}:* #{instant_message_extraction[ :body ]}"
  
  # Find the thread name parameter from url in database and go to the thread
  thread_object = FbThread.find_with_receive_endpoint( thread_nickname )
  return if thread_object.nil?
  thread_id = thread_object.fb_url_id
  
  post_message_to_facebook_thread( send_to_facebook_content, thread_id )
end

get '/api/jim/push/fb/:thread' do
  thread_nickname = params[ :thread ]
  @fb_thread_from_database = FbThread.find_by_nickname( thread_nickname )  
  thread_api_key = @fb_thread_from_database.chat_room_api_key
  
  require 'jaconda'  
  Jaconda::API.authenticate( :subdomain => thread_nickname,
                            :token => thread_api_key )
  room = Jaconda::API::Room.find thread_nickname
  
  current_message_id = 0
  room.messages.each do |message|
    current_message_id = message.id
    
    if message.kind != 'chat'
      next
    end
    
    if @fb_thread_from_database.last_chat_room_message_id.to_i >= current_message_id
      next
    end
    
    body = message.text    
    #@TODO should match chat user id with fb user and then try to post message as that fb user before falling back to a fb bot
    thread_id = @fb_thread_from_database.fb_url_id
    
    post_message_to_facebook_thread( "*#{body}", thread_id )
  end
  
  if current_message_id != @fb_thread_from_database.last_chat_room_message_id
    @fb_thread_from_database.update_column( 'last_chat_room_message_id', current_message_id )
  end  
end


get '/api/fb/push/partychat/threads' do
  require 'koala'
  me = Koala::Facebook::API.new( ENV[ 'fb_api' ] )
    
  total_sent_messages_count = 0
  # Get all the threads and latest messages at once for account to save time from polling FB API for each thread
  threads = me.get_object( "me/inbox?&since=#{Time.now.to_i - 1000}" )
  threads.each do |single_thread|
    # Skip the current thread if it isn't the database - meaning it doesn't need pushing
    @fb_thread_from_database = FbThread.find_by_fb_api_id( single_thread[ 'id' ] )
    next if @fb_thread_from_database.nil?
        
    thread_sent_messages_count = 0
    # Needs to work outside the loop below so the final one can update the latest message id column in database
    current_message_id = 0    
    # Only take in the hash part for [recent] messages
    last_25_messages = single_thread[ 'comments' ][ 'data' ]
    last_25_messages.each do |message_hash|      
      # All the numbers before the underscore are just the thread id the message is in
      current_message_id = message_hash[ 'id' ].sub( /^\d+_/, '' )
      
      # FB bumps each new message id in a thread up by one.
      # If last message id from db is greater (happened after the current message you're looking at), skip it
      if @fb_thread_from_database.last_message_id.to_i >= current_message_id.to_i
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

get '/api/fb/push/jim/threads' do
  require 'koala'
  me = Koala::Facebook::API.new( ENV[ 'fb_api' ] )
  
  total_sent_messages_count = 0
  # Get all the threads and latest messages at once for account to save time from polling FB API for each thread
  recent_time = Time.now.to_i - 1000
  recent_time = recent_time.to_s
  threads = me.get_object( "me/inbox?&since=#{recent_time}" )

  threads.each do |single_thread|
    # Skip the current thread if it isn't the database - meaning it doesn't need pushing
    @fb_thread_from_database = FbThread.find_by_fb_api_id( single_thread[ 'id' ] )
    next if @fb_thread_from_database.nil?
    #next if @fb_thread_from_database.ignore == true
     
    thread_sent_messages_count = 0
    # Needs to work outside the loop below so the final one can update the latest message id column in database
    current_message_id = 0    
    # Only take in the hash part for [recent] messages
    last_25_messages = single_thread[ 'comments' ][ 'data' ]
    last_25_messages.each do |message_hash|
      # All the numbers before the underscore are just the thread id the message is in
      current_message_id = message_hash[ 'id' ].sub( /^\d+_/, '' )
      
      # FB bumps each new message id in a thread up by one.
      # If last message id from db is greater (happened after the current message you're looking at), skip it
      if @fb_thread_from_database.last_message_id.to_i >= current_message_id.to_i
        next
      end
      
      # Get who sent the message
      sender = message_hash[ 'from' ][ 'id' ]
      sender = FbMember.find_by_fb_id( sender )
      
      message = message_hash[ 'message' ]
      
      if message.start_with? '*'
        next
      end
      
      message_from_facebook_to_jaconda( @fb_thread_from_database, sender.name, message )
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


get '/api/4sq/push/checkins' do
  require 'foursquare2'
  client = Foursquare2::Client.new(:oauth_token => ENV[ 'foursquare_oauth' ] )
  
  # Hardcoded which FB thread to post to
  fb_thread = FbThread.find ENV[ 'foursquare_push_thread_id' ]
  fb_thread_id = fb_thread.fb_url_id
  
  recent = client.recent_checkins
  
  # In-efficient, keeps looping even after finding correct stuff in second inner loop
  FoursquareMember.all.each do |foursquare_member|
    latest_foursquare_checkin_id = '1'
    recent.each do |individual|
      
      # Check to see if matching database person and current iteration of api checkin person
      if foursquare_member.foursquare_id != individual[ 'user' ][ 'id' ]
        next
      end
      
      # Now we know we have the correct person from database and api so any further situations where
      # we won't be pushing to Facebook or after we are done pushing can kill the loop and move to next person in db
      
      # Check if already pushed their most recent checkin. If so no need to continue, on to next person
      latest_foursquare_checkin_id = individual[ 'id' ]
      if foursquare_member.last_checkin_id == latest_foursquare_checkin_id
        break
      end
      
      location_name = individual[ 'venue' ][ 'name' ]
      send_to_facebook_content = "@Foursquare: #{foursquare_member.fb_member.name} checked into #{location_name}."
      
      # If there is no shout and checkin is blacklisted, skip pushing
      # However if there is a shout, push the checkin even if blacklisted
      
      # Check for shout/comment
      shout = individual[ 'shout' ]
      if shout.nil? || shout.empty?
        
        # Check to see if checkin location is blacklisted and push should be skipped
        venue_id = individual[ 'venue' ][ 'id' ]
        venue_find = FoursquareLocationBlacklist.find( :first, :conditions => [ 'foursquare_member_id = ? and location_id = ?', foursquare_member.id, venue_id ] )
        if !venue_find.nil?
          break
        end
        
      else
        send_to_facebook_content << " [S]he shouted, \"#{shout}\"."
      end
      
      single_checkin = client.checkin( latest_foursquare_checkin_id )
      send_to_facebook_content << " Points: +#{single_checkin[ 'score' ][ 'total' ]}."
            
      post_message_to_facebook_thread( send_to_facebook_content, fb_thread_id )
      break
    end
    
    # Update the database with the latest checkin id if new
    if foursquare_member.last_checkin_id != latest_foursquare_checkin_id
      foursquare_member.update_column( 'last_checkin_id', latest_foursquare_checkin_id )
    end
  end
  'Done'
end


# Eh
get '/' do
  'Nup'
end


helpers do
  def login_and_save_cookie( page )
    cookie_location = './tmp/fb_cookie.yml'
    
    login_form = page.form_with( :id => 'login_form' )
    
    login_form[ 'email' ] = ENV[ 'fb_user' ]
    login_form[ 'pass' ] = ENV[ 'fb_pass' ]
    page = login_form.submit# 'login'
    
    # Not sure how to get Mechanize to directly give cookie information
    # Instead saving the cookie information to file, and dumping that file's content into db
    @agent.cookie_jar.save_as( cookie_location )
    fb_cookie = IO.read cookie_location
        
    bot_object = FbMember.find_by_fb_user ENV[ 'fb_user']
    bot_object.update_column( 'fb_cookie', fb_cookie )
    
    return page
  end
  
  def message_from_facebook_to_partychat( http_endpoint, sender, message )
    ##
    # Posting to Partychat or well any url that is a post hook
    ##        
    require 'uri'
    require 'net/http'
        
    params = { 'person' => sender, 'message' => message }
        
    Net::HTTP.post_form( URI.parse( http_endpoint ), params )
  end
  
  def message_from_facebook_to_jaconda( fb_thread_object, sender, message )
    require 'jaconda'
    Jaconda::Notification.authenticate( :subdomain => fb_thread_object.nickname,
                                       :room_id => fb_thread_object.nickname,
                                       :room_token => fb_thread_object.chat_room_api_token )

    Jaconda::Notification.notify( :text => message,
                                 :sender_name => sender )
  end
  
  def post_message_to_facebook_thread( send_to_facebook_content, thread_id )
    require 'mechanize'
    @agent = Mechanize.new
    # Not sure how to have Mechanize just take in cookie information from string without this implementation
    # Pulling Mechanize's cookie info from db, dumping it into a file, and then loading said file into Mechanize
    cookie_location = './tmp/fb_cookie.yml'
    fb_cookie = FbMember.find_by_fb_user( ENV[ 'fb_user' ] ).fb_cookie
    if !fb_cookie.nil? && !fb_cookie.empty?
      File.open( cookie_location, 'w' ) do | file |
        file.puts fb_cookie
      end
      @agent.cookie_jar.load( cookie_location )
    end
  
    facebook_site = @agent.get( 'http://m.facebook.com/messages' )
  
    # Check to see if url has redirected to login page. If so, then it means not logged in.
    current_url = facebook_site.uri.to_s
    current_path = URI.parse( current_url ).path
    # If cookie doesn't have you signed in, manually log in and get fresh cookie
    if !current_path.include? 'messages'
      facebook_site = login_and_save_cookie( facebook_site )
    end
        
    individual_thread_url = "https://m.facebook.com/messages/read?action=read&tid=id.#{thread_id}"
    individual_thread = @agent.get( individual_thread_url )
  
    # Post to the message text area on specific thread page
    reply_form = individual_thread.form_with( :id => 'composer_form' )
    reply_form[ 'body' ] = send_to_facebook_content
    reply_form.submit
    
    return individual_thread
  end
end
