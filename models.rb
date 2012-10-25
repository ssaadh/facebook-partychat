class FbMember < ActiveRecord::Base
  attr_accessible :fb_id, :name, :google_talk_name, :is_bot
end

class FbThread < ActiveRecord::Base
  attr_accessible :fb_id, :last_message_id, :name, :nickname, :ignore, :post_http_endpoint, :receive_http_endpoint
  
  def self.find_with_receive_endpoint( url_parameter )
    self.find_by_nickname( url_parameter.titleize )    
  end
end

class FbMessage
  
end