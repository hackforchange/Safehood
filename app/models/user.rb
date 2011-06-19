class User < ActiveRecord::Base
  has_many :messages, :dependent=>:nullify
  acts_as_mappable :lng_column_name => :lon, :units=>:km
  validates_uniqueness_of :phone
  #assume a maximum radius of 1km
  MAXIMUM_RADIUS = 1
  
  def nearby_users
    #TODO: actually do this right, without retarded GEOKIT STUPID STUPIDNESS
    #all users who are within subscription range
    
    #from bounds
    b = Geokit::Bounds.from_point_and_radius(self,1,:units=>:km)
    lng_sql = b.crosses_meridian? ? "(lon<#{b.ne.lng} OR lon>#{b.sw.lng})" : "lon>#{b.sw.lng} AND lon<#{b.ne.lng}"
    bounds_sql = "lat>#{b.sw.lat} AND lat<#{b.ne.lat} AND #{lng_sql}"
    

    self.class.where(bounds_sql).where("id <> ?",self.id)
  end

end
