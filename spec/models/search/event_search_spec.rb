require 'spec_helper'

describe Event, type: :model, search: true do
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
    team = FactoryGirl.create(:team, company: company)
    team2 = FactoryGirl.create(:team, company: company)
    user = FactoryGirl.create(:company_user, company: company, team_ids: [team.id], role: FactoryGirl.create(:role, company: company))
    user2 = FactoryGirl.create(:company_user, company: company, team_ids: [team.id, team2.id], role: FactoryGirl.create(:role, company: company))
    user3 = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, company: company))
    user4 = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, company: company))
    place = FactoryGirl.create(:place, city: 'Los Angeles', state: 'California', country: 'US')
    place2 = FactoryGirl.create(:place, city: 'Chicago')
    event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place, team_ids: [team.id], user_ids: [user3.id], start_date: "02/22/2013", end_date: "02/23/2013")
    event2 = FactoryGirl.create(:event, company: company, campaign: campaign2, place: place2, team_ids: [team.id, team2.id], user_ids: [user3.id, user4.id], start_date: "03/22/2013", end_date: "03/22/2013")

    area = FactoryGirl.create(:area, company: company)
    area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')

    area2 = FactoryGirl.create(:area, company: company)
    area2.places << place

    # Create a Campaign and an Event on company 2
    company2_campaign = FactoryGirl.create(:campaign)
    company2_event = FactoryGirl.create(:event, company: company2_campaign.company, campaign: company2_campaign)

    Sunspot.commit

    # Make some test searches

    # Search by event id
    expect(Event.do_search(company_id: company.id, id: [event.id, event2.id]).results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, id: [event.id]).results).to match_array([event])
    expect(Event.do_search(company_id: company.id, id: [event2.id]).results).to match_array([event2])

    # Search for all Events on a given Company
    expect(Event.do_search(company_id: company.id).results).to match_array([event, event2])
    expect(Event.do_search(company_id: company2_campaign.company_id).results).to match_array([company2_event])

    expect(Event.do_search({company_id: company.id, q: "team,#{team.id}"}, true).results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, q: "team,#{team2.id}").results).to match_array([event2])

    # Search for a specific user's Events
    expect(Event.do_search(company_id: company.id, q: "company_user,#{user3.id}").results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, q: "company_user,#{user4.id}").results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, user: [user3.id]).results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, user: [user4.id]).results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, user: [user3.id,user4.id]).results).to match_array([event, event2])

    # Search for a specific Event's place
    expect(Event.do_search(company_id: company.id, q: "place,#{place.id}").results).to match_array([event])
    expect(Event.do_search(company_id: company.id, q: "place,#{place2.id}").results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, place: [place.id]).results).to match_array([event])
    expect(Event.do_search(company_id: company.id, place: [place2.id]).results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, place: [place.id, place2.id]).results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, location: [place.location_id]).results).to match_array([event])
    expect(Event.do_search(company_id: company.id, location: [place2.location_id]).results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, location: [place.location_id, place2.location_id]).results).to match_array([event, event2])

    # Search for a events in an area
    expect(Event.do_search(company_id: company.id, q: "area,#{area.id}").results).to match_array([event])
    expect(Event.do_search(company_id: company.id, area: [area.id]).results).to match_array([event])
    expect(Event.do_search(company_id: company.id, q: "area,#{area2.id}").results).to match_array([event])
    expect(Event.do_search(company_id: company.id, area: [area2.id]).results).to match_array([event])

    # Search for brands associated to the Events
    expect(Event.do_search(company_id: company.id, q: "brand,#{brand.id}").results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, q: "brand,#{brand2.id}").results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, brand: brand.id).results).to match_array([event, event2])
    expect(Event.do_search(company_id: company.id, brand: brand2.id).results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, brand: [brand.id, brand2.id]).results).to match_array([event, event2])

    # Search for campaigns associated to the Events
    expect(Event.do_search(company_id: company.id, q: "campaign,#{campaign.id}").results).to match_array([event])
    expect(Event.do_search(company_id: company.id, q: "campaign,#{campaign2.id}").results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, campaign: campaign.id).results).to match_array([event])
    expect(Event.do_search(company_id: company.id, campaign: campaign2.id).results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, campaign: [campaign.id, campaign2.id]).results).to match_array([event, event2])

    # Search for Events on a given date range
    expect(Event.do_search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013').results).to match_array([event])
    expect(Event.do_search(company_id: company.id, start_date: '02/22/2013').results).to match_array([event])
    expect(Event.do_search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013').results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, start_date: '03/22/2013').results).to match_array([event2])
    expect(Event.do_search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013').results).to eq([])

    # Search for Events on a given status
    expect(Event.do_search(company_id: company.id, status: ['Active']).results).to match_array([event, event2])

    # Search for Events on a given event status
    expect(Event.do_search(company_id: company.id, event_status: ['Unsent']).results).to match_array([event, event2])
    Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
      dummy_event = FactoryGirl.create(:event)
      dummy_event.start_date = '07/18/2013'
      dummy_event.end_date = '07/23/2013'
      dummy_event.save
      Sunspot.commit

      expect(Event.do_search(company_id: dummy_event.company_id, event_status: ['Late']).results).to match_array([dummy_event])

      dummy_event.end_date = '07/25/2013'
      dummy_event.save
      Sunspot.commit

      expect(Event.do_search(company_id: dummy_event.company_id, event_status: ['Due']).results).to match_array([dummy_event])
    end

    #Search for Events with stats
    expect(Event.do_search({company_id: company.id, event_data_stats: true}).results).to match_array([event, event2])
  end

  it "should not fail if a brand without campaings is given" do
    company = FactoryGirl.create(:company)
    FactoryGirl.create(:event, company: company)

    Sunspot.commit
    # Invalid brand
    expect(Event.do_search(company_id: company.id, brand: 1).results).to match_array([])

    # Brand without campaings
    brand = FactoryGirl.create(:brand)
    expect(Event.do_search(company_id: company.id, brand: brand.id).results).to match_array([])
  end
end