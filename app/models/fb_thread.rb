class FbThread < ActiveRecord::Base
  attr_accessible :fb_id, :last_message_id, :name, :ignore, :post_http_endpoint, :receive_http_endpoint
end
