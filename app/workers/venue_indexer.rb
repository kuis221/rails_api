class VenueIndexer
  @queue = :indexing

  def self.perform(venue_id)
    begin
      Venue.find(venue_id).compute_stats
    rescue
    end
  end
end