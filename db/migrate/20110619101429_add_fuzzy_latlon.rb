class AddFuzzyLatlon < ActiveRecord::Migration
  def self.up
    add_column :messages, :fuzzy_lat, :float
    add_column :messages, :fuzzy_lon, :float
  end

  def self.down
    remove_column :messages, :fuzzy_lat
    remove_column :messages, :fuzzy_lon
  end
end
