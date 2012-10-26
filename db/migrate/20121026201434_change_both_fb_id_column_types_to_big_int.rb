class ChangeBothFbIdColumnTypesToBigInt < ActiveRecord::Migration
  def change
    change_column :fb_members, :fb_id, :bigint
    change_column :fb_threads, :fb_id, :bigint
  end
end
