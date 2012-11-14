class CreateFbThreads < ActiveRecord::Migration
  def change
    create_table :fb_threads do |t|
      t.string :fb_id
      t.string :name
      t.integer :last_message_id
      t.boolean :ignore

      t.timestamps
    end
  end
end
