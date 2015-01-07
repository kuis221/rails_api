class PlaceYelpUpdaterWorker
  include Resque::Plugins::UniqueJob

  @queue = :indexing

  def self.perform(place_id)
    place = Place.find(place_id)
    place.find_yelp_business
    place.save if place.yelp_business_id
  rescue
  end
end
