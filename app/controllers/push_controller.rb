class PushController < ApplicationController
  def latest_thread_messages    
    me = Koala::Facebook::API.new( 'AAAEJYBfN694BAKi3YGolMZBD9roUZAAsnfjJ6n5cSohXsuMSgGF0ZC6TIyES2f3NMp1ukAqVFk19EG82pvDD86fvUpZBVUVZBdO01sWLAxwZDZD' )
    
    thread_id = 269517366500096
    
    @fb_thread = FbThread.find_by_fb_id( thread_id )
    
    last_25_messages = me.get_object( thread_id )[ 'comments' ][ 'data' ]
    
    last_25_messages.each do |message_hash|
      @message_id = message_hash[ 'id' ].sub( /#{thread_id}_/, '' ).to_i
      
      if @fb_thread.last_message_id >= @message_id
        next
      end
      
      sender = message_hash[ 'from' ][ 'id' ]
      sender = FbMember.find_by_fb_id( sender )
      
      sent_time = message_hash[ 'created_time' ].to_time.in_time_zone( 'Eastern Time (US & Canada)' ).strftime( '%I:%M %p' )
      
      message = message_hash[ 'message' ]
      
      require 'uri'
      require 'net/http'
 
      params = { 'person' => sender.name, 'message' => message }
    
      Net::HTTP.post_form( URI.parse( @fb_thread.post_http_endpoint ), params )      
    end
    
    @fb_thread.update_column( 'last_message_id', @message_id )
  end
end
