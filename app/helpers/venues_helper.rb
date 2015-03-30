module VenuesHelper
  def upcomming_venue_events_list
    @venue_events = Event.do_search(
      company_id: current_company.id,
      current_company_user: current_company_user,
      venue: [resource.id], per_page: 5,
      sorting: :start_at, sorting_dir: :asc,
      start_date: [Time.zone.now.strftime('%m/%d/%Y')],
      end_date: [(Time.zone.now + 10.years).strftime('%m/%d/%Y')])
    @venue_events_total = @venue_events.total
    @venue_events.results
  end

  def is_demographic_empty?(data)
    return true if data.blank? || data.map(&:last).uniq.first == 0
  end

  def link_to_get_directions(venue)
    address = [venue.street, venue.city, venue.state, venue.zipcode, venue.country].join(' ')
    link_to 'Get Directions', "https://maps.google.com?#{ { daddr: address }.to_query }",
            class: 'get-venue-directions', target: '_blank'
  end
end
