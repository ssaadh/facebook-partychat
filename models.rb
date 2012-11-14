class FbMember < ActiveRecord::Base
  attr_accessible :fb_id, :name, :google_talk_name, :is_bot
  
  has_one :foursquare_member
end

class FbThread < ActiveRecord::Base
  attr_accessible :fb_id, :last_message_id, :name, :nickname, :ignore, :post_http_endpoint, :receive_http_endpoint
  
  def self.find_with_receive_endpoint( url_parameter )
    self.find_by_nickname( url_parameter.titleize )    
  end
end

class FbMessage
end

class FoursquareMember < ActiveRecord::Base
  attr_accessible :fb_member_id, :foursquare_id, :last_checkin_id
  
  belongs_to :fb_member
end

class FoursquareLocationBlacklist < ActiveRecord::Base
  attr_accessible :foursquare_member_id, :location_id
end