require 'rails_helper'

describe Event, type: :model, search: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  after { Timecop.return }

  it 'should search for events' do
    # First populate the Database with some data
    brand = create(:brand)
    brand2 = create(:brand)
    campaign = create(:campaign, company: company, brand_ids: [brand.id])
    campaign2 = create(:campaign, company: company, brand_ids: [brand.id, brand2.id])
    team = create(:team, company: company)
    team2 = create(:team, company: company)
    create(:company_user, company: company, team_ids: [team.id],
                          role: create(:role, company: company))
    create(:company_user, company: company, team_ids: [team.id, team2.id],
                          role: create(:role, company: company))
    user3 = create(:company_user, company: company, role: create(:role, company: company))
    user4 = create(:company_user, company: company, role: create(:role, company: company))
    place = create(:place, city: 'Los Angeles', state: 'California', country: 'US')
    place2 = create(:place, city: 'Chicago')
    event = create(:event, campaign: campaign, place: place,
                           team_ids: [team.id], user_ids: [user3.id],
                           start_date: '02/22/2013', end_date: '02/23/2013')
    event2 = create(:event, campaign: campaign2, place: place2,
                            team_ids: [team.id, team2.id], user_ids: [user3.id, user4.id],
                            start_date: '03/22/2013', end_date: '03/22/2013')

    area = create(:area, company: company)
    area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

    area2 = create(:area, company: company)
    area2.places << place

    # Create a Campaign and an Event on company 2
    company2_campaign = create(:campaign)
    company2_event = create(:event, campaign: company2_campaign)

    # Make some test searches

    # Search by event id
    expect(search(company_id: company.id, id: [event.id, event2.id]))
      .to match_array([event, event2])
    expect(search(company_id: company.id, id: [event.id]))
      .to match_array([event])
    expect(search(company_id: company.id, id: [event2.id]))
      .to match_array([event2])

    # Search for all Events on a given Company
    expect(search(company_id: company.id))
      .to match_array([event, event2])
    expect(search(company_id: company2_campaign.company_id))
      .to match_array([company2_event])

    expect(search({ company_id: company.id, q: "team,#{team.id}" }, true))
      .to match_array([event, event2])
    expect(search(company_id: company.id, q: "team,#{team2.id}"))
      .to match_array([event2])

    # Search for a specific user's Events
    expect(search(company_id: company.id, q: "company_user,#{user3.id}"))
      .to match_array([event, event2])
    expect(search(company_id: company.id, q: "company_user,#{user4.id}"))
      .to match_array([event2])
    expect(search(company_id: company.id, user: [user3.id]))
      .to match_array([event, event2])
    expect(search(company_id: company.id, user: [user4.id]))
      .to match_array([event2])
    expect(search(company_id: company.id, user: [user3.id, user4.id]))
      .to match_array([event, event2])

    # Search for a specific Event's place
    expect(search(company_id: company.id, q: "place,#{place.id}"))
      .to match_array([event])
    expect(search(company_id: company.id, q: "place,#{place2.id}"))
      .to match_array([event2])
    expect(search(company_id: company.id, place: [place.id]))
      .to match_array([event])
    expect(search(company_id: company.id, place: [place2.id]))
      .to match_array([event2])
    expect(search(company_id: company.id, place: [place.id, place2.id]))
      .to match_array([event, event2])
    expect(search(company_id: company.id, location: [place.location_id]))
      .to match_array([event])
    expect(search(company_id: company.id, location: [place2.location_id]))
      .to match_array([event2])
    expect(search(company_id: company.id, location: [place.location_id, place2.location_id]))
      .to match_array([event, event2])

    # Search for a events in an area
    expect(search(company_id: company.id, q: "area,#{area.id}"))
      .to match_array([event])
    expect(search(company_id: company.id, area: [area.id]))
      .to match_array([event])
    expect(search(company_id: company.id, q: "area,#{area2.id}"))
      .to match_array([event])
    expect(search(company_id: company.id, area: [area2.id]))
      .to match_array([event])

    # Search for brands associated to the Events
    expect(search(company_id: company.id, q: "brand,#{brand.id}"))
      .to match_array([event, event2])
    expect(search(company_id: company.id, q: "brand,#{brand2.id}"))
      .to match_array([event2])
    expect(search(company_id: company.id, brand: brand.id))
      .to match_array([event, event2])
    expect(search(company_id: company.id, brand: brand2.id))
      .to match_array([event2])
    expect(search(company_id: company.id, brand: [brand.id, brand2.id]))
      .to match_array([event, event2])

    # Search for campaigns associated to the Events
    expect(search(company_id: company.id, q: "campaign,#{campaign.id}"))
      .to match_array([event])
    expect(search(company_id: company.id, q: "campaign,#{campaign2.id}"))
      .to match_array([event2])
    expect(search(company_id: company.id, campaign: campaign.id))
      .to match_array([event])
    expect(search(company_id: company.id, campaign: campaign2.id))
      .to match_array([event2])
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id]))
      .to match_array([event, event2])

    # Search for Events on a given date range
    expect(search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013'))
      .to match_array([event])
    expect(search(company_id: company.id, start_date: '02/22/2013'))
      .to match_array([event])
    expect(search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013'))
      .to match_array([event2])
    expect(search(company_id: company.id, start_date: '03/22/2013'))
      .to match_array([event2])
    expect(search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013'))
      .to be_empty

    # Search for Events on a given status
    expect(search(company_id: company.id, status: ['Active']))
      .to match_array([event, event2])

    # Search for Events on a given event status
    expect(search(company_id: company.id, event_status: ['Unsent']))
      .to match_array([event, event2])
    Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
      dummy_event = create(:event)
      dummy_event.start_date = '07/18/2013'
      dummy_event.end_date = '07/23/2013'
      dummy_event.save

      expect(search(company_id: dummy_event.company_id, event_status: ['Late']))
        .to match_array([dummy_event])

      dummy_event.end_date = '07/25/2013'
      dummy_event.save

      expect(search(company_id: dummy_event.company_id, event_status: ['Due']))
        .to match_array([dummy_event])
    end

    # Search for Events with stats
    expect(search(company_id: company.id, event_data_stats: true))
      .to match_array([event, event2])
  end

  describe 'TrendObject indexing' do
    let(:field) { create(:form_field_text_area, fieldable: campaign) }
    let(:campaign) { create(:campaign) }
    let(:event) { create(:event, campaign: campaign) }

    it 'should create a TrendObject if the event have any trending result' do
      event.results_for([field]).first.value = 'value'
      event.save

      Sunspot.commit

      search = TrendObject.do_search(company_id: campaign.company_id, term: 'value')
      expect(search.results.map(&:resource))
        .to match_array [event]

      # Now unset the result and make sure its removed from the index
      event.results_for([field]).first.value = ''
      event.save

      Sunspot.commit

      search = TrendObject.do_search(company_id: campaign.company_id, term: 'value')
      expect(search.results.map(&:resource)).to be_empty
    end
  end

  it 'should not fail if a brand without campaings is given' do
    create(:event, campaign: campaign)

    Sunspot.commit
    # Invalid brand
    expect(search(company_id: company.id, brand: 1))
      .to be_empty

    # Brand without campaings
    brand = create(:brand)
    expect(search(company_id: company.id, brand: brand.id))
      .to be_empty
  end
end
