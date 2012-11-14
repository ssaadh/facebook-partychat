class CreateFoursquareMembers < ActiveRecord::Migration
  def change
    create_table :foursquare_members do |t|
      t.integer :fb_member_id
      t.string :foursquare_id
      t.string :last_checkin_id

      t.timestamps
    end
  end
end
