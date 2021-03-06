class Location < ActiveRecord::Base
  has_and_belongs_to_many :eventdates

  validates_presence_of :building, :floor, :room
  
  scope :active, -> { where(defunct: false) }

  def to_s
    return (building + " - " + room);
  end
end
