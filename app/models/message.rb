class Message < ActiveRecord::Base
  belongs_to :user
  acts_as_mappable :lng_column_name => :lon
  
  def self.backlogged(phone_number)
    where("user_id is null AND phone = ? AND created_at > ?",phone_number,Date.yesterday)
  end
  
  def self.safe_fields
    select([:created_at, :lat, :lon, :message])
  end
end
