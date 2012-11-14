class AddSecondFbIdColumnToFbThreads < ActiveRecord::Migration
  def change
    rename_column :fb_threads, :fb_id, :fb_api_id
    add_column :fb_threads, :fb_url_id, :bigint
  end
end
