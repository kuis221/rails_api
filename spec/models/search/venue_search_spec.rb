require 'rails_helper'

describe Venue, type: :model, search: true do
  it 'should search for venues' do
    # First populate the Database with some data
    company = create(:company)
    brand = create(:brand)
    brand2 = create(:brand)
    campaign = create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    place = create(:place, name: 'Island Creek Oyster Bar', city: 'Boston', latitude: '42.348774', longitude: '-71.094994')
    place2 = create(:place, name: 'Bar None', city: 'San Francisco', latitude: '37.79764', longitude: '-122.431913')
    event = create(:event, campaign: campaign, place: place)
    event2 = create(:event, campaign: campaign2, place: place2)
    venue = event.venue
    venue2 = event2.venue

    # Create a Venue on company 2
    company2 = create(:company)
    company2_place = create(:place, name: 'Bar 4 Vientos', city: 'Cartago')
    company2_event = create(:event, company: company2, place: company2_place)
    company2_venue = company2_event.venue

    Venue.reindex

    Sunspot.commit

    # Search for all Venues on a given Company
    expect(Venue.do_search(company_id: company.id).results).to match_array([venue, venue2])
    expect(Venue.do_search(company_id: company2.id).results).to match_array([company2_venue])

    # Search for a specific Venue's place
    expect(Venue.do_search(company_id: company.id, locations: [place.location_id]).results).to match_array([venue])
    expect(Venue.do_search(company_id: company.id, locations: [place2.location_id]).results).to match_array([venue2])
    expect(Venue.do_search(company_id: company.id, locations: [place.location_id, place2.location_id]).results).to match_array([venue, venue2])

    # Search for campaigns associated to the Venues
    expect(Venue.do_search(company_id: company.id, campaign: campaign.id).results).to match_array([venue])
    expect(Venue.do_search(company_id: company.id, campaign: campaign2.id).results).to match_array([venue2])
    expect(Venue.do_search(company_id: company.id, campaign: [campaign.id, campaign2.id]).results).to match_array([venue, venue2])

    # Search for brands associated to the Venues
    expect(Venue.do_search(company_id: company.id, brand: brand.id).results).to match_array([venue, venue2])
    expect(Venue.do_search(company_id: company.id, brand: brand2.id).results).to match_array([venue2])
    expect(Venue.do_search(company_id: company.id, brand: [brand.id, brand2.id]).results).to match_array([venue, venue2])

    # Range filters
    [:events_count, :promo_hours, :impressions, :interactions, :sampled, :spent, :venue_score].each do |option|
      if option.to_s == 'venue_score'
        venue.score = 5
      else
        venue.send("#{option}=", 5)
      end

      venue.save
      Venue.reindex
      Sunspot.commit

      expect(Venue.do_search(company_id: company.id, option => { min: 1, max: 5 }).results).to match_array([venue])
      expect(Venue.do_search(company_id: company.id, option => { min: 1, max: 6 }).results).to match_array([venue])
      expect(Venue.do_search(company_id: company.id, option => { min: 10, max: 12 }).results).to match_array([])
      expect(Venue.do_search(company_id: company.id, option => { min: 3 }).results).to match_array([venue])
      expect(Venue.do_search(company_id: company.id, option => { min: 5 }).results).to match_array([venue])
      expect(Venue.do_search(company_id: company.id, option => { min: 6 }).results).to match_array([])
    end

    # Search for a given Venue
    expect(Venue.do_search({ company_id: company.id, loc_name: 'San Francisco, CA', q: 'none', location: '37.7749295,-122.41941550000001' }, true).results).to match_array([venue2])

    # Search for Venues on a given status
    expect(Venue.do_search(company_id: company.id, status: ['Active']).results).to match_array([venue, venue2])
  end

  describe 'search by campaing' do
    it 'should include any venue that is part of the campaign scope' do
      company = create(:company)
      sf = create(:place, city: 'San Francisco', state: 'CA', country: 'US', types: %w(political locality))
      campaign = create(:campaign, company: company)
      campaign.places << sf

      venue_sf1 = create(:venue, place: create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_sf2 = create(:venue, place: create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_la  = create(:venue, place: create(:place, name: 'Place in LA',  city: 'Los Angeles', state: 'CA', country: 'US', types: ['establishment']), company: company)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: company.id, campaign: [campaign.id])

      # Should include the venues from sf but not the venue from L.A.
      expect(result.results).to match_array([venue_sf1, venue_sf2])
    end
  end

  describe 'user permissions' do
    it 'should include only venues that are between the user permissions' do
      company = create(:company)
      sf = create(:place, city: 'San Francisco', state: 'CA', country: 'US', types: ['political'])

      campaign = create(:campaign, company: company)
      non_accessible_campaign = create(:campaign, company: company)

      venue_sf1 = create(:venue, place: create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_sf2 = create(:venue, place: create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_la  = create(:venue, place: create(:place, name: 'Place in LA',  city: 'Los Angeles', state: 'CA', country: 'US', types: ['establishment']), company: company)

      # Create a non admin user
      company_user = create(:company_user, company: company, role: create(:non_admin_role))

      company_user.places << sf  # Give the user access to San Francisco

      # company_user.campaigns << campaign  # Give the user access to the campaign

      # # Create a event for each venue on a campaing that the user doesn't have access
      # create(:event, place_id: venue_sf1.place_id, campaign: non_accessible_campaign)
      # create(:event, place_id: venue_sf2.place_id, campaign: non_accessible_campaign)
      # create(:event, place_id: venue_la.place_id, campaign: non_accessible_campaign)

      Venue.reindex
      Sunspot.commit

      # result = Venue.do_search(company_id: company.id, campaign: company_user)

      # # Should not include venues that have no events on the accessible campaigns for the user
      # expect(result.results).to match_array([])

      # Create a event for each venue
      create(:event, place_id: venue_sf1.place_id, campaign: campaign)
      create(:event, place_id: venue_sf2.place_id, campaign: campaign)
      create(:event, place_id: venue_la.place_id, campaign: campaign)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: company.id, current_company_user: company_user)

      # Should not include the venue from L.A. because it's not accessible for the user
      expect(result.results).to match_array([venue_sf1, venue_sf2])

      # Finally, it should return all the venues if the user is a super admin
      super_admin = create(:company_user, company_id: company.id, role: create(:role))
      result = Venue.do_search(company_id: company.id, current_company_user: super_admin)
      expect(result.results).to match_array([venue_sf1, venue_sf2, venue_la])
    end
  end
end
