class Message < ActiveRecord::Base
  belongs_to :user
  
  def self.backlogged(phone_number)
    where("user_id is null AND phone = ? AND created_at > ?",phone_number,Date.yesterday)
  end
end
