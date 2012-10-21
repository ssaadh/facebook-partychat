class PushController < ApplicationController
  def latest_thread_messages    
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
end
