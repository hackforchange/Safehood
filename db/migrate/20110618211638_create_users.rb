class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :phone
      t.string :location
      t.float  :lat
      t.float  :lon
      t.float  :radius #in meters
      t.boolean :active
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
