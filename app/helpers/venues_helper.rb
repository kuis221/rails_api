module VenuesHelper
  def upcomming_venue_events_list
    @venue_events = Event.do_search({company_id: current_company.id, current_company_user: current_company_user, q: "venue,#{resource.id}", per_page: 5, sorting: :start_at, sorting_dir: :asc, start_date: Time.zone.now.strftime("%m/%d/%Y"), end_date: Time.zone.now + 10.years})
    @venue_events_total = @venue_events.total
    @venue_events.results
  end
  
  def is_demographic_empty?(data)
    return true if data.blank? or data.map(&:last).uniq.first == 0
  end
end