class AddFbUserInfoAndFbCookieToFbMember < ActiveRecord::Migration
  def change
    add_column :fb_members, :fb_user, :string
    add_column :fb_members, :fb_pass, :string
    add_column :fb_members, :fb_cookie, :string
  end
end
