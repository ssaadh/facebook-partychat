class AddChatRoomApiTokenToFbThread < ActiveRecord::Migration
  def up
    add_column :fb_threads, :chat_room_api_token, :string
  end

  def down
    remove_column :fb_threads, :chat_room_api_token
  end
end
