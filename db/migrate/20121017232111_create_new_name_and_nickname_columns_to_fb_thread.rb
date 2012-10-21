class CreateNewNameAndNicknameColumnsToFbThread < ActiveRecord::Migration
  def up
    rename_column :fb_threads, :name, :nickname
    add_column :fb_threads, :name, :string
  end
  
  def down
    remove_column :fb_threads, :name
    rename_column :fb_threads, :nickname, :name
  end
end
