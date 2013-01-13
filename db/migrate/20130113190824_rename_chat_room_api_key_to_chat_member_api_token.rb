class RenameChatRoomApiKeyToChatMemberApiToken < ActiveRecord::Migration
  def up
    rename_column :fb_threads, :chat_room_api_key, :chat_member_api_token
  end

  def down
    rename_column :fb_threads, :chat_member_api_token, :chat_room_api_key
  end
end
