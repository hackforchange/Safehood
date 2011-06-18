class AddPhoneToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :phone, :string
  end

  def self.down
    remove_column :messages, :phone
  end
end
