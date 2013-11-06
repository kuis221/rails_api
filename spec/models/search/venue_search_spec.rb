require 'spec_helper'

describe Venue, search: true do
  it "should search for venues" do
    # First populate the Database with some data
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    campaign = FactoryGirl.create(:campaign, company_id: 1, brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company_id: 1, brand_ids: [brand.id, brand2.id])
    place = FactoryGirl.create(:place, name: 'Island Creek Oyster Bar', city: "Boston", latitude: '42.348774', longitude: '-71.094994')
    place2 = FactoryGirl.create(:place, name: 'Bar None', city: "San Francisco", latitude: '37.79764', longitude: '-122.431913')
    event = FactoryGirl.create(:event, company_id: 1, campaign: campaign, place: place)
    event2 = FactoryGirl.create(:event, company_id: 1, campaign: campaign2, place: place2)
    venue = event.venue
    venue2 = event2.venue

    # Create a Venue on company 2
    company2_place = FactoryGirl.create(:place, name: 'Bar 4 Vientos', city: "Cartago")
    company2_event = FactoryGirl.create(:event, company_id: 2, place: company2_place)
    company2_venue = company2_event.venue

    Sunspot.commit

    # Search for all Venues on a given Company
    Venue.do_search(company_id: 1).results.should =~ [venue, venue2]
    Venue.do_search(company_id: 2).results.should =~ [company2_venue]

    # Search for a specific Venue's place
    place_id = "#{Place.location_for_index(place)}||#{place.name}"
    place2_id = "#{Place.location_for_index(place2)}||#{place2.name}"
    Venue.do_search(company_id: 1, place: [Base64.encode64(place_id)]).results.should =~ [venue]
    Venue.do_search(company_id: 1, place: [Base64.encode64(place2_id)]).results.should =~ [venue2]
    Venue.do_search(company_id: 1, place: [Base64.encode64(place_id), Base64.encode64(place2_id)]).results.should =~ [venue, venue2]

    # Search for campaigns associated to the Venues
    Venue.do_search(company_id: 1, campaign: campaign.id).results.should =~ [venue]
    Venue.do_search(company_id: 1, campaign: campaign2.id).results.should =~ [venue2]
    Venue.do_search(company_id: 1, campaign: [campaign.id, campaign2.id]).results.should =~ [venue, venue2]

    # Search for brands associated to the Venues
    Venue.do_search(company_id: 1, brand: brand.id).results.should =~ [venue, venue2]
    Venue.do_search(company_id: 1, brand: brand2.id).results.should =~ [venue2]
    Venue.do_search(company_id: 1, brand: [brand.id, brand2.id]).results.should =~ [venue, venue2]

    # Range filters
    [:events, :promo_hours, :impressions, :interactions, :sampled, :spent, :venue_score].each do |option|
      if option.to_s == 'venue_score'
        venue.score = 5
      else
        venue.send("#{option}=", 5)
      end

      venue.save
      Sunspot.commit

      Venue.do_search(company_id: 1, option => {min: 1, max: 5}).results.should =~ [venue]
      Venue.do_search(company_id: 1, option => {min: 1, max: 6}).results.should =~ [venue]
      Venue.do_search(company_id: 1, option => {min: 10, max: 12}).results.should =~ []
      Venue.do_search(company_id: 1, option => {min: 3}).results.should =~ [venue]
      Venue.do_search(company_id: 1, option => {min: 5}).results.should =~ [venue]
      Venue.do_search(company_id: 1, option => {min: 6}).results.should =~ []
    end

    # Search for a given Venue
    Venue.do_search({company_id: 1, loc_name: "San Francisco, CA", q: "none", location: '37.7749295,-122.41941550000001'}, true).results.should =~ [venue2]

    # Search for Venues on a given status
    Venue.do_search(company_id: 1, status: ['Active']).results.should =~ [venue, venue2]
  end

  describe "search by campaing" do
    it "should include any venue that is part of the campaign scope" do
      SF = FactoryGirl.create(:place, city: 'San Francisco', state: 'CA', country: 'US', types: ['political'])
      campaign = FactoryGirl.create(:campaign, company_id: 1)
      campaign.places << SF

      venue_sf1 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']))
      venue_sf2 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']))
      venue_la  = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in LA',  city: 'Los Angeles', state: 'CA', country: 'US', types: ['establishment']))

      Sunspot.commit

      result = Venue.do_search(company_id: 1, campaign: [campaign.id])

      # Should include the venues from sf but not the venue from L.A.
      result.results.should =~ [venue_sf1, venue_sf2]
    end
  end

  describe "user permissions" do
    it "should include only venues that are between the user permissions" do
      SF = FactoryGirl.create(:place, city: 'San Francisco', state: 'CA', country: 'US', types: ['political'])

      campaign = FactoryGirl.create(:campaign, company_id: 1)
      non_accessible_campaign = FactoryGirl.create(:campaign, company_id: 1)

      venue_sf1 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']))
      venue_sf2 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in SF1', city: 'San Francisco', state: 'CA', country: 'US', types: ['establishment']))
      venue_la  = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, name: 'Place in LA',  city: 'Los Angeles', state: 'CA', country: 'US', types: ['establishment']))

      # Create a non admin user
      company_user = FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:non_admin_role))

      company_user.places << SF  # Give the user access to San Francisco
      company_user.campaigns << campaign  # Give the user access to the campaign

      # Create a event for each venue on a campaing that the user doesn't have access
      FactoryGirl.create(:event, place_id: venue_sf1.place_id, campaign: non_accessible_campaign)
      FactoryGirl.create(:event, place_id: venue_sf2.place_id, campaign: non_accessible_campaign)
      FactoryGirl.create(:event, place_id: venue_la.place_id, campaign: non_accessible_campaign)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: 1, current_company_user: company_user)

      # Should not include venues that have no events on the accessible campaigns for the user
      result.results.should =~ []


      # Create a event for each venue
      FactoryGirl.create(:event, place_id: venue_sf1.place_id, campaign: campaign)
      FactoryGirl.create(:event, place_id: venue_sf2.place_id, campaign: campaign)
      FactoryGirl.create(:event, place_id: venue_la.place_id, campaign: campaign)

      Venue.reindex
      Sunspot.commit

      result = Venue.do_search(company_id: 1, current_company_user: company_user)

      # Should not include the venue from L.A. because it's not accessible for the user
      result.results.should =~ [venue_sf1, venue_sf2]

      # Finally, it should return all the venues if the user is a super admin
      super_admin = FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role))
      result = Venue.do_search(company_id: 1, current_company_user: super_admin)
      result.results.should =~ [venue_sf1, venue_sf2, venue_la]
    end
  end
end