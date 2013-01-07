class AddLastChatRoomMessageIdToFbThread < ActiveRecord::Migration
  def up
    add_column :fb_threads, :last_chat_room_message_id, :integer
  end

  def down
    remove_column :fb_threads, :last_chat_room_message_id
  end
end
