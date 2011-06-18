class Message < ActiveRecord::Base
  belongs_to :user
  acts_as_mappable :lng_column_name => :lon
end
