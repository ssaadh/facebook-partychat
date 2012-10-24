class AddLastMessageDateimeToFbThread < ActiveRecord::Migration
  def change
    add_column :fb_threads, :last_message_datetime, :datetime
  end
end
