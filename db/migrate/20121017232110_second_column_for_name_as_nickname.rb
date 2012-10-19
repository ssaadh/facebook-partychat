class SecondColumnForNameAsNicknameToFbThread < ActiveRecord::Migration
  def up
    change_column :fb_threads, :name, :nickname
    add_column :fb_threads, :name, :string
  end
  
  def down
    remove_column :fb_threads, :name
    change_column :fb_threads, :nickname, :name
  end
end
