class AddChatRoomApiKeyToFbThread < ActiveRecord::Migration
  def up
    add_column :fb_threads, :chat_room_api_key, :string
  end

  def down
    remove_column :fb_threads, :chat_room_api_key
  end
end
