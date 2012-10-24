class AddGoogleTalkNameToFbMember < ActiveRecord::Migration
  def change
    add_column :fb_members, :google_talk_name, :string
  end
end
