class AddIsBotBooleanToFbMember < ActiveRecord::Migration
  def change
    add_column :fb_members, :is_bot, :boolean
  end
end
