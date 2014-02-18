require 'spec_helper'

describe Event, search: true do
  after do
    Timecop.return
  end

  it "should search for events" do
    company = FactoryGirl.create(:company)
    # First populate the Database with some data
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    campaign = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    team = FactoryGirl.create(:team)
    team2 = FactoryGirl.create(:team)
    user = FactoryGirl.create(:company_user, company: company, team_ids: [team.id], role: FactoryGirl.create(:role))
    user2 = FactoryGirl.create(:company_user, company: company, team_ids: [team.id, team2.id], role: FactoryGirl.create(:role))
    user3 = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role))
    user4 = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role))
    place = FactoryGirl.create(:place, city: 'Los Angeles', state: 'California', country: 'US')
    place2 = FactoryGirl.create(:place, city: 'Chicago')
    event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place, team_ids: [team.id], user_ids: [user3.id], start_date: "02/22/2013", end_date: "02/23/2013")
    event2 = FactoryGirl.create(:event, company: company, campaign: campaign2, place: place2, team_ids: [team.id, team2.id], user_ids: [user3.id, user4.id], start_date: "03/22/2013", end_date: "03/22/2013")

    area = FactoryGirl.create(:area, company: company)
    area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')

    # Create a Campaign and an Event on company 2
    company2_campaign = FactoryGirl.create(:campaign)
    company2_event = FactoryGirl.create(:event, company: company2_campaign.company, campaign: company2_campaign)

    Sunspot.commit

    # Make some test searches

    # Search for all Events on a given Company
    Event.do_search(company_id: company.id).results.should =~ [event, event2]
    Event.do_search(company_id: company2_campaign.company_id).results.should =~ [company2_event]

    Event.do_search({company_id: company.id, q: "team,#{team.id}"}, true).results.should =~ [event, event2]
    Event.do_search(company_id: company.id, q: "team,#{team2.id}").results.should =~ [event2]

    # Search for a specific user's Events
    Event.do_search(company_id: company.id, q: "company_user,#{user3.id}").results.should =~ [event, event2]
    Event.do_search(company_id: company.id, q: "company_user,#{user4.id}").results.should =~ [event2]
    Event.do_search(company_id: company.id, user: [user3.id]).results.should =~ [event, event2]
    Event.do_search(company_id: company.id, user: [user4.id]).results.should =~ [event2]
    Event.do_search(company_id: company.id, user: [user3.id,user4.id]).results.should =~ [event, event2]

    # Search for a specific Event's place
    Event.do_search(company_id: company.id, q: "place,#{place.id}").results.should =~ [event]
    Event.do_search(company_id: company.id, q: "place,#{place2.id}").results.should =~ [event2]
    Event.do_search(company_id: company.id, location: [place.location_id]).results.should =~ [event]
    Event.do_search(company_id: company.id, location: [place2.location_id]).results.should =~ [event2]
    Event.do_search(company_id: company.id, location: [place.location_id, place2.location_id]).results.should =~ [event, event2]

    # Search for a events in an area
    Event.do_search(company_id: company.id, q: "area,#{area.id}").results.should =~ [event]
    Event.do_search(company_id: company.id, area: [area.id]).results.should =~ [event]

    # Search for brands associated to the Events
    Event.do_search(company_id: company.id, q: "brand,#{brand.id}").results.should =~ [event, event2]
    Event.do_search(company_id: company.id, q: "brand,#{brand2.id}").results.should =~ [event2]
    Event.do_search(company_id: company.id, brand: brand.id).results.should =~ [event, event2]
    Event.do_search(company_id: company.id, brand: brand2.id).results.should =~ [event2]
    Event.do_search(company_id: company.id, brand: [brand.id, brand2.id]).results.should =~ [event, event2]

    # Search for campaigns associated to the Events
    Event.do_search(company_id: company.id, q: "campaign,#{campaign.id}").results.should =~ [event]
    Event.do_search(company_id: company.id, q: "campaign,#{campaign2.id}").results.should =~ [event2]
    Event.do_search(company_id: company.id, campaign: campaign.id).results.should =~ [event]
    Event.do_search(company_id: company.id, campaign: campaign2.id).results.should =~ [event2]
    Event.do_search(company_id: company.id, campaign: [campaign.id, campaign2.id]).results.should =~ [event, event2]

    # Search for Events on a given date range
    Event.do_search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013').results.should =~ [event]
    Event.do_search(company_id: company.id, start_date: '02/22/2013').results.should =~ [event]
    Event.do_search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013').results.should =~ [event2]
    Event.do_search(company_id: company.id, start_date: '03/22/2013').results.should =~ [event2]
    Event.do_search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013').results.should == []

    # Search for Events on a given status
    Event.do_search(company_id: company.id, status: ['Active']).results.should =~ [event, event2]

    # Search for Events on a given event status
    Event.do_search(company_id: company.id, event_status: ['Unsent']).results.should =~ [event, event2]
    Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
      dummy_event = FactoryGirl.create(:event)
      dummy_event.start_date = '07/18/2013'
      dummy_event.end_date = '07/23/2013'
      dummy_event.save
      Sunspot.commit

      Event.do_search(company_id: dummy_event.company_id, event_status: ['Late']).results.should =~ [dummy_event]

      dummy_event.end_date = '07/25/2013'
      dummy_event.save
      Sunspot.commit

      Event.do_search(company_id: dummy_event.company_id, event_status: ['Due']).results.should =~ [dummy_event]
    end

    #Search for Events with stats
    Event.do_search({company_id: company.id, event_data_stats: true}).results.should =~ [event, event2]
  end

  it "should not fail if a brand without campaings is given" do
    company = FactoryGirl.create(:company)
    FactoryGirl.create(:event, company: company)

    Sunspot.commit
    # Invalid brand
    Event.do_search(company_id: company.id, brand: 1).results.should =~ []

    # Brand without campaings
    brand = FactoryGirl.create(:brand)
    Event.do_search(company_id: company.id, brand: brand.id).results.should =~ []
  end
end