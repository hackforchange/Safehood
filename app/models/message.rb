class Message < ActiveRecord::Base
  belongs_to :user
  acts_as_mappable :lng_column_name => :lon
  
  cattr_reader :per_page
  @@per_page = 20
  
  class << self

    def backlogged(phone_number)
      where("user_id is null AND phone = ? AND created_at > ?",phone_number,Date.yesterday)
    end
    
    def safe_fields
      select([:created_at, :lat, :lon, :message])
    end
    
    def textsearch(q)
      where("message like ?","%#{q}%")
    end
    
    def boundbox(south,north,east,west)
      west,east = [east,west].minmax
      south,north = [south,north].minmax
      where("lat > ? AND lat < ? AND lon > ? AND lon < ?",south,north,west,east)
    end
    
  end
end
