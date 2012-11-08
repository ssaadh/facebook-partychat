class ChangeFbCookieTypeToTextInFbMember < ActiveRecord::Migration
  def change
    change_column :fb_members, :fb_cookie, :text
  end
end
