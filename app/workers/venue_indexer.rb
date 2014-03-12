class VenueIndexer
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(venue_id)
    begin
      Rails.logger.info "Started VenueIndexer job: venue_id=#{venue_id}"
      Venue.find(venue_id).compute_stats
      Rails.logger.info "Finished VenueIndexer job: venue_id=#{venue_id}"
    rescue
    end
  end
end