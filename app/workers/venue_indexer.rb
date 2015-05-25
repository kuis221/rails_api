class VenueIndexer
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(venue_id)
    Rails.logger.info "Started VenueIndexer job: venue_id=#{venue_id}"
    Venue.find(venue_id).compute_stats
    Rails.logger.info "Finished VenueIndexer job: venue_id=#{venue_id}"
  rescue Resque::TermException, Resque::DirtyExit
    # if the worker gets killed, (when deploying for example)
    # re-enqueue the job so it will be processed when worker is restarted
    Resque.enqueue(VenueIndexer, venue_id)
  end
end
