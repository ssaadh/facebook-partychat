class CreateFbMembers < ActiveRecord::Migration
  def change
    create_table :fb_members do |t|
      t.integer :fb_id
      t.string :name

      t.timestamps
    end
  end
end
