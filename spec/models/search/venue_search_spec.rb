require 'rails_helper'

describe Venue, type: :model, search: true do
  it 'should search for venues' do
    # First populate the Database with some data
    company = create(:company)
    brand = create(:brand)
    brand2 = create(:brand)
    campaign = create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    place = create(:place, name: 'Island Creek Oyster Bar', city: 'Boston',
                           lonlat: 'POINT(-71.094994 42.348774)')
    place2 = create(:place, name: 'Bar None', city: 'San Francisco',
                            lonlat: 'POINT(-122.431913 37.79764)')
    event = create(:event, campaign: campaign, place: place,
                           start_date: '02/22/2013', end_date: '02/23/2013')
    event2 = create(:event, campaign: campaign2, place: place2,
                            start_date: '03/22/2013', end_date: '03/22/2013')
    venue = event.venue
    venue2 = event2.venue

    # Create a Venue on company 2
    company2 = create(:company)
    company2_place = create(:place, name: 'Bar 4 Vientos', city: 'Cartago')
    company2_event = create(:event, company: company2, place: company2_place)
    company2_venue = company2_event.venue

    # Search for all Venues on a given Company
    expect(search(company_id: company.id))
      .to match_array([venue, venue2])
    expect(search(company_id: company2.id))
      .to match_array([company2_venue])

    # Search for all Venues with a given id
    expect(search(company_id: company.id, venue: [venue.id]))
      .to match_array([venue])
    expect(search(company_id: company.id, venue: [venue2.id]))
      .to match_array([venue2])
    expect(search(company_id: company.id, venue: [venue.id, venue2.id]))
      .to match_array([venue, venue2])

    # Search for a specific Venue's place
    expect(search(company_id: company.id, locations: [place.location_id]))
      .to match_array([venue])
    expect(search(company_id: company.id, locations: [place2.location_id]))
      .to match_array([venue2])
    expect(search(company_id: company.id, locations: [place.location_id, place2.location_id]))
      .to match_array([venue, venue2])

    # Search for campaigns associated to the Venues
    expect(search(company_id: company.id, campaign: campaign.id))
      .to match_array([venue])
    expect(search(company_id: company.id, campaign: campaign2.id))
      .to match_array([venue2])
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id]))
      .to match_array([venue, venue2])

    # Search for brands associated to the Venues
    expect(search(company_id: company.id, brand: brand.id))
      .to match_array([venue, venue2])
    expect(search(company_id: company.id, brand: brand2.id))
      .to match_array([venue2])
    expect(search(company_id: company.id, brand: [brand.id, brand2.id]))
      .to match_array([venue, venue2])

    # Search for Venues with events on a given date range
    expect(search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013'))
      .to match_array([venue])
    expect(search(company_id: company.id, start_date: '02/22/2013'))
      .to match_array([venue])
    expect(search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013'))
      .to match_array([venue2])
    expect(search(company_id: company.id, start_date: '03/22/2013'))
      .to match_array([venue2])
    expect(search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013'))
      .to be_empty

    # Range filters
    [:events_count, :promo_hours, :impressions, :interactions,
     :sampled, :spent, :venue_score].each do |option|
      if option.to_s == 'venue_score'
        venue.score = 5
      else
        venue.send("#{option}=", 5)
      end

      venue.save

      expect(search(company_id: company.id, option => { min: 1, max: 5 }))
        .to match_array([venue])
      expect(search(company_id: company.id, option => { min: 1, max: 6 }))
        .to match_array([venue])
      expect(search(company_id: company.id, option => { min: 10, max: 12 }))
        .to match_array([])
      expect(search(company_id: company.id, option => { min: 3 }))
        .to match_array([venue])
      expect(search(company_id: company.id, option => { min: 5 }))
        .to match_array([venue])
      expect(search(company_id: company.id, option => { min: 6 }))
        .to match_array([])
    end

    # Search for a given Venue
    expect(
      search(company_id: company.id, loc_name: 'San Francisco, CA',
             q: 'none', location: '37.7749295,-122.41941550000001')
    ).to match_array([venue2])

    # Search for Venues on a given status
    expect(search(company_id: company.id, status: ['Active']))
      .to match_array([venue, venue2])
  end

  describe 'search by campaing' do
    it 'should include any venue that is part of the campaign scope' do
      company = create(:company)
      sf = create(:city, name: 'San Francisco', state: 'CA', country: 'US')
      campaign = create(:campaign, company: company)
      campaign.places << sf

      venue_sf1 = create(:venue,
                         place: create(:place, name: 'Place in SF1', city: 'San Francisco',
                                       state: 'CA', country: 'US'),
                         company: company)
      venue_sf2 = create(:venue,
                         place: create(:place, name: 'Place in SF1', city: 'San Francisco',
                                       state: 'CA', country: 'US'),
                         company: company)
      create(:venue,
             place: create(:place, name: 'Place in LA',  city: 'Los Angeles',
                           state: 'CA', country: 'US'),
             company: company)
      # Should include the venues from sf but not the venue from L.A.
      expect(search(company_id: company.id, campaign: [campaign.id]))
          .to match_array([venue_sf1, venue_sf2])
    end
  end

  describe 'user permissions' do
    it 'should include only venues that are between the user permissions' do
      company = create(:company)
      sf = create(:city, name: 'San Francisco', state: 'CA', country: 'US')

      campaign = create(:campaign, company: company)
      # non accessible campaign
      create(:campaign, company: company)

      venue_sf1 = create(:venue,
                         place: create(:place, name: 'Place in SF1', city: 'San Francisco',
                                       state: 'CA', country: 'US'),
                         company: company)
      venue_sf2 = create(:venue,
                         place: create(:place, name: 'Place in SF1', city: 'San Francisco',
                                       state: 'CA', country: 'US'),
                         company: company)
      venue_la  = create(:venue,
                         place: create(:place, name: 'Place in LA',  city: 'Los Angeles',
                                       state: 'CA', country: 'US'),
                         company: company)

      # Create a non admin user
      company_user = create(:company_user, company: company, role: create(:non_admin_role))

      company_user.places << sf  # Give the user access to San Francisco

      # Create a event for each venue
      create(:event, place_id: venue_sf1.place_id, campaign: campaign)
      create(:event, place_id: venue_sf2.place_id, campaign: campaign)
      create(:event, place_id: venue_la.place_id, campaign: campaign)

      # Should not include the venue from L.A. because it's not accessible for the user
      expect(search(company_id: company.id, current_company_user: company_user))
        .to match_array([venue_sf1, venue_sf2])

      # Finally, it should return all the venues if the user is a super admin
      super_admin = create(:company_user, company_id: company.id, role: create(:role))
      expect(search(company_id: company.id, current_company_user: super_admin))
        .to match_array([venue_sf1, venue_sf2, venue_la])
    end
  end
end
