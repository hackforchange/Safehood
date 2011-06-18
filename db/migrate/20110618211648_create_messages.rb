class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.references :user
      t.string :message
      t.string :location
      t.float :lat
      t.float :lon
      t.string :hashed_phone
      t.string :hashed_ip
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
