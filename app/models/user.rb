class User < ActiveRecord::Base
  has_many :messages
  #assume a maximum radius of 1km
  
  def nearby_users
    #TODO
    #all users who are within subscription range
    User.all
  end

end
