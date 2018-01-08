class User < ApplicationRecord


  has_many :groups, through: :group_users
  has_many :group_users
  has_many :route_logs

  validates :token,     presence: true
  validates :latitude,  presence: true
  validates :longitude, presence: true
  validates :speed,     presence: true
  validates :bearing,   presence: true

end
