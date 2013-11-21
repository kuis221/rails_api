require 'spec_helper'

describe Event, search: true do
  it "should search for events" do

    # First populate the Database with some data
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    campaign = FactoryGirl.create(:campaign, company_id: 1, brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company_id: 1, brand_ids: [brand.id, brand2.id])
    team = FactoryGirl.create(:team)
    team2 = FactoryGirl.create(:team)
    user = FactoryGirl.create(:company_user, company_id: 1, team_ids: [team.id], role: FactoryGirl.create(:role))
    user2 = FactoryGirl.create(:company_user, company_id: 1, team_ids: [team.id, team2.id], role: FactoryGirl.create(:role))
    user3 = FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role))
    user4 = FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role))
    place = FactoryGirl.create(:place, city: 'Los Angeles')
    place2 = FactoryGirl.create(:place, city: 'Chicago')
    event = FactoryGirl.create(:event, company_id: 1, campaign: campaign, place: place, team_ids: [team.id], user_ids: [user3.id], start_date: "02/22/2013", end_date: "02/23/2013")
    event2 = FactoryGirl.create(:event, company_id: 1, campaign: campaign2, place: place2, team_ids: [team.id, team2.id], user_ids: [user3.id, user4.id], start_date: "03/22/2013", end_date: "03/22/2013")

    # Create a Campaign and an Event on company 2
    company2_campaign = FactoryGirl.create(:campaign, company_id: 2)
    company2_event = FactoryGirl.create(:event, company_id: 2, campaign: company2_campaign)

    Sunspot.commit

    # Make some test searches

    # Search for all Events on a given Company
    Event.do_search(company_id: 1).results.should =~ [event, event2]
    Event.do_search(company_id: 2).results.should =~ [company2_event]

    Event.do_search({company_id: 1, q: "team,#{team.id}"}, true).results.should =~ [event, event2]
    Event.do_search(company_id: 1, q: "team,#{team2.id}").results.should =~ [event2]

    # Search for a specific user's Events
    Event.do_search(company_id: 1, q: "company_user,#{user3.id}").results.should =~ [event, event2]
    Event.do_search(company_id: 1, q: "company_user,#{user4.id}").results.should =~ [event2]
    Event.do_search(company_id: 1, user: [user3.id]).results.should =~ [event, event2]
    Event.do_search(company_id: 1, user: [user4.id]).results.should =~ [event2]
    Event.do_search(company_id: 1, user: [user3.id,user4.id]).results.should =~ [event, event2]

    # Search for a specific Event's place
    place_id = "#{Place.location_for_index(place)}||#{place.name}"
    place2_id = "#{Place.location_for_index(place2)}||#{place2.name}"
    Event.do_search(company_id: 1, q: "place,#{place.id}").results.should =~ [event]
    Event.do_search(company_id: 1, q: "place,#{place2.id}").results.should =~ [event2]
    Event.do_search(company_id: 1, place: [Base64.encode64(place_id)]).results.should =~ [event]
    Event.do_search(company_id: 1, place: [Base64.encode64(place2_id)]).results.should =~ [event2]
    Event.do_search(company_id: 1, place: [Base64.encode64(place_id), Base64.encode64(place2_id)]).results.should =~ [event, event2]

    # Search for brands associated to the Events
    Event.do_search(company_id: 1, q: "brand,#{brand.id}").results.should =~ [event, event2]
    Event.do_search(company_id: 1, q: "brand,#{brand2.id}").results.should =~ [event2]
    Event.do_search(company_id: 1, brand: brand.id).results.should =~ [event, event2]
    Event.do_search(company_id: 1, brand: brand2.id).results.should =~ [event2]
    Event.do_search(company_id: 1, brand: [brand.id, brand2.id]).results.should =~ [event, event2]

    # Search for campaigns associated to the Events
    Event.do_search(company_id: 1, q: "campaign,#{campaign.id}").results.should =~ [event]
    Event.do_search(company_id: 1, q: "campaign,#{campaign2.id}").results.should =~ [event2]
    Event.do_search(company_id: 1, campaign: campaign.id).results.should =~ [event]
    Event.do_search(company_id: 1, campaign: campaign2.id).results.should =~ [event2]
    Event.do_search(company_id: 1, campaign: [campaign.id, campaign2.id]).results.should =~ [event, event2]

    # Search for Events on a given date range
    Event.do_search(company_id: 1, start_date: '02/21/2013', end_date: '02/23/2013').results.should =~ [event]
    Event.do_search(company_id: 1, start_date: '02/22/2013').results.should =~ [event]
    Event.do_search(company_id: 1, start_date: '03/21/2013', end_date: '03/23/2013').results.should =~ [event2]
    Event.do_search(company_id: 1, start_date: '03/22/2013').results.should =~ [event2]
    Event.do_search(company_id: 1, start_date: '01/21/2013', end_date: '01/23/2013').results.should == []

    # Search for Events on a given status
    Event.do_search(company_id: 1, status: ['Active']).results.should =~ [event, event2]

    # Search for Events on a given event status
    Event.do_search(company_id: 1, event_status: ['Unsent']).results.should =~ [event, event2]
    Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
      dummy_event = FactoryGirl.create(:event, company_id: 2)
      dummy_event.start_date = '07/18/2013'
      dummy_event.end_date = '07/23/2013'
      dummy_event.save
      Sunspot.commit

      Event.do_search(company_id: 2, event_status: ['Late']).results.should =~ [dummy_event]

      dummy_event.end_date = '07/25/2013'
      dummy_event.save
      Sunspot.commit

      Event.do_search(company_id: 2, event_status: ['Due']).results.should =~ [dummy_event]
    end

    #Search for Events with stats
    Event.do_search({company_id: 1, event_data_stats: true}).results.should =~ [event, event2]
  end

  it "should not fail if a brand without campaings is given" do
    FactoryGirl.create(:event, company_id: 1)

    Sunspot.commit
    # Invalid brand
    Event.do_search(company_id: 1, brand: 1).results.should =~ []

    # Brand without campaings
    brand = FactoryGirl.create(:brand)
    Event.do_search(company_id: 1, brand: brand.id).results.should =~ []
  end
end