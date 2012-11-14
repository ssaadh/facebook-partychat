class CreateFoursquareLocationBlacklists < ActiveRecord::Migration
  def change
    create_table :foursquare_location_blacklists do |t|
      t.integer :foursquare_member_id
      t.string :location_id

      t.timestamps
    end
  end
end
