class VenueIndexer
  include Sidekiq::Worker
  sidekiq_options queue: :indexing, retry: 3

  def perform(venue_id)
    Rails.logger.info "Started VenueIndexer job: venue_id=#{venue_id}"
    Venue.find(venue_id).compute_stats
    Rails.logger.info "Finished VenueIndexer job: venue_id=#{venue_id}"
  end
end
