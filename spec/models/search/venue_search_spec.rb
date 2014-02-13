require 'spec_helper'

describe Venue, search: true do
  it "should search for venues" do
    # First populate the Database with some data
    company = FactoryGirl.create(:company)
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    campaign = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    place = FactoryGirl.create(:place, name: 'Island Creek Oyster Bar', city: "Boston", latitude: '42.348774', longitude: '-71.094994')
    place2 = FactoryGirl.create(:place, name: 'Bar None', city: "San Francisco", latitude: '37.79764', longitude: '-122.431913')
    event = FactoryGirl.create(:event, campaign: campaign, place: place)
    event2 = FactoryGirl.create(:event, campaign: campaign2, place: place2)
    venue = event.venue
    venue2 = event2.venue

    # Create a Venue on company 2
    company2 = FactoryGirl.create(:company)
    company2_place = FactoryGirl.create(:place, name: 'Bar 4 Vientos', city: "Cartago")
    company2_event = FactoryGirl.create(:event, company: company2, place: company2_place)
    company2_venue = company2_event.venue

    Venue.reindex

    Sunspot.commit

    # Search for all Venues on a given Company
    Venue.do_search(company_id: company.id).results.should =~ [venue, venue2]
    Venue.do_search(company_id: company2.id).results.should =~ [company2_venue]

    # Search for a specific Venue's place
    Venue.do_search(company_id: company.id, locations: [place.location_id]).results.should =~ [venue]
    Venue.do_search(company_id: company.id, locations: [place2.location_id]).results.should =~ [venue2]
    Venue.do_search(company_id: company.id, locations: [place.location_id, place2.location_id]).results.should =~ [venue, venue2]

    # Search for campaigns associated to the Venues
    Venue.do_search(company_id: company.id, campaign: campaign.id).results.should =~ [venue]
    Venue.do_search(company_id: company.id, campaign: campaign2.id).results.should =~ [venue2]
    Venue.do_search(company_id: company.id, campaign: [campaign.id, campaign2.id]).results.should =~ [venue, venue2]

    # Search for brands associated to the Venues
    Venue.do_search(company_id: company.id, brand: brand.id).results.should =~ [venue, venue2]
    Venue.do_search(company_id: company.id, brand: brand2.id).results.should =~ [venue2]
    Venue.do_search(company_id: company.id, brand: [brand.id, brand2.id]).results.should =~ [venue, venue2]

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

      Venue.do_search(company_id: company.id, option => {min: 1, max: 5}).results.should =~ [venue]
      Venue.do_search(company_id: company.id, option => {min: 1, max: 6}).results.should =~ [venue]
      Venue.do_search(company_id: company.id, option => {min: 10, max: 12}).results.should =~ []
      Venue.do_search(company_id: company.id, option => {min: 3}).results.should =~ [venue]
      Venue.do_search(company_id: company.id, option => {min: 5}).results.should =~ [venue]
      Venue.do_search(company_id: company.id, option => {min: 6}).results.should =~ []
    end

    # Search for a given Venue
    Venue.do_search({company_id: company.id, loc_name: "San Francisco, CA", q: "none", location: '37.7749295,-122.41941550000001'}, true).results.should =~ [venue2]

    # Search for Venues on a given status
    Venue.do_search(company_id: company.id, status: ['Active']).results.should =~ [venue, venue2]
  end

  describe "search by campaing" do
    it "should include any venue that is part of the campaign scope" do
      company = FactoryGirl.create(:company)
      sf = FactoryGirl.create(:place, city: 'San Francisco', state: 'CA', country: 'US', types: ['political', 'locality'])
      campaign = FactoryGirl.create(:campaign, company: company)
      campaign.places << sf

      venue_sf1 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_sf2 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_la  = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in LA',  city: 'Los Angeles', state: 'CA', country: 'US', types: ['establishment']), company: company)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: company.id, campaign: [campaign.id])

      # Should include the venues from sf but not the venue from L.A.
      result.results.should =~ [venue_sf1, venue_sf2]
    end
  end

  describe "user permissions" do
    it "should include only venues that are between the user permissions" do
      company = FactoryGirl.create(:company)
      sf = FactoryGirl.create(:place, city: 'San Francisco', state: 'CA', country: 'US', types: ['political'])

      campaign = FactoryGirl.create(:campaign, company: company)
      non_accessible_campaign = FactoryGirl.create(:campaign, company: company)

      venue_sf1 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_sf2 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']), company: company)
      venue_la  = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in LA',  city: 'Los Angeles', state: 'CA', country: 'US', types: ['establishment']), company: company)

      # Create a non admin user
      company_user = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:non_admin_role))

      company_user.places << sf  # Give the user access to San Francisco
      company_user.campaigns << campaign  # Give the user access to the campaign

      # Create a event for each venue on a campaing that the user doesn't have access
      FactoryGirl.create(:event, place_id: venue_sf1.place_id, campaign: non_accessible_campaign)
      FactoryGirl.create(:event, place_id: venue_sf2.place_id, campaign: non_accessible_campaign)
      FactoryGirl.create(:event, place_id: venue_la.place_id, campaign: non_accessible_campaign)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: company.id, current_company_user: company_user)

      # Should not include venues that have no events on the accessible campaigns for the user
      result.results.should =~ []


      # Create a event for each venue
      FactoryGirl.create(:event, place_id: venue_sf1.place_id, campaign: campaign)
      FactoryGirl.create(:event, place_id: venue_sf2.place_id, campaign: campaign)
      FactoryGirl.create(:event, place_id: venue_la.place_id, campaign: campaign)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: company.id, current_company_user: company_user)

      # Should not include the venue from L.A. because it's not accessible for the user
      result.results.should =~ [venue_sf1, venue_sf2]

      # Finally, it should return all the venues if the user is a super admin
      super_admin = FactoryGirl.create(:company_user, company_id: company.id, role: FactoryGirl.create(:role))
      result = Venue.do_search(company_id: company.id, current_company_user: super_admin)
      result.results.should =~ [venue_sf1, venue_sf2, venue_la]
    end
  end
end