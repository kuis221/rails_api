require 'rails_helper'

describe Event, type: :model, search: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  after { Timecop.return }

  it 'should search for events' do
    # First populate the Database with some data
    brand = create(:brand, company: company)
    brand2 = create(:brand, company: company)
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
    place2 = create(:place, city: 'Chicago', state: 'Illinois')
    event = create(:event, campaign: campaign, place: place,
                           team_ids: [team.id], user_ids: [user3.id],
                           start_date: '02/22/2013', end_date: '02/23/2013')
    event2 = create(:event, campaign: campaign2, place: place2,
                            team_ids: [team.id, team2.id], user_ids: [user3.id, user4.id],
                            start_date: '03/22/2013', end_date: '03/22/2013')

    venue = event.venue
    venue2 = event2.venue

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

    expect(search({ company_id: company.id, team: [team.id] }, true))
      .to match_array([event, event2])
    expect(search(company_id: company.id, team: [team2.id]))
      .to match_array([event2])

    # Search for a specific user's Events
    expect(search(company_id: company.id, user: [user3.id]))
      .to match_array([event, event2])
    expect(search(company_id: company.id, user: [user4.id]))
      .to match_array([event2])
    expect(search(company_id: company.id, user: [user3.id, user4.id]))
      .to match_array([event, event2])

    # Search for a specific Event's place
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

    # Search for a specific Event's venue
    expect(search(company_id: company.id, venue: [venue.id]))
      .to match_array([event])
    expect(search(company_id: company.id, venue: [venue2.id]))
      .to match_array([event2])
    expect(search(company_id: company.id, venue: [venue.id, venue2.id]))
      .to match_array([event, event2])

    # Search for a events in an area
    expect(search(company_id: company.id, area: [area.id]))
      .to match_array([event])
    expect(search(company_id: company.id, area: [area2.id]))
      .to match_array([event])

    # Search for brands associated to the Events
    expect(search(company_id: company.id, brand: brand.id))
      .to match_array([event, event2])
    expect(search(company_id: company.id, brand: brand2.id))
      .to match_array([event2])
    expect(search(company_id: company.id, brand: [brand.id, brand2.id]))
      .to match_array([event, event2])

    # Search for campaigns associated to the Events
    expect(search(company_id: company.id, campaign: campaign.id))
      .to match_array([event])
    expect(search(company_id: company.id, campaign: campaign2.id))
      .to match_array([event2])
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id]))
      .to match_array([event, event2])

    # Search for Events on a given date range
    expect(search(company_id: company.id, start_date: ['02/21/2013'], end_date: ['02/23/2013']))
      .to match_array([event])
    expect(search(company_id: company.id, start_date: ['02/22/2013']))
      .to match_array([event])
    expect(search(company_id: company.id, start_date: ['03/21/2013'], end_date: ['03/23/2013']))
      .to match_array([event2])
    expect(search(company_id: company.id, start_date: ['03/22/2013']))
      .to match_array([event2])
    expect(search(company_id: company.id, start_date: ['01/21/2013'], end_date: ['01/23/2013']))
      .to be_empty

    # Search for Events on a given status
    expect(search(company_id: company.id, status: ['Active']))
      .to match_array([event, event2])

    # Search for Events with Late status
    late_event = create(:late_event)
    Sunspot.commit
    expect(search(company_id: late_event.company_id, event_status: ['Late'])).to eql [late_event]

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

  it 'searches retricted to users params' do
    # First populate the Database with some data
    campaign = create(:campaign, company: company)
    campaign2 = create(:campaign, company: company)

    user = create(:company_user, company: company, role: create(:non_admin_role, company: company))
    user.role.permissions.create(action: 'view_list', subject_class: 'Event', mode: 'campaigns')

    place = create(:place, city: 'Los Angeles', state: 'California')
    place2 = create(:place, city: 'Chicago', state: 'Illinois')

    event = create(:event, campaign: campaign, place: place,
                           start_date: '02/22/2013', end_date: '02/23/2013')
    event2 = create(:event, campaign: campaign2, place: place2,
                            start_date: '03/22/2013', end_date: '03/22/2013')


    area = create(:area, company: company)
    area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

    user.areas << area
    user.campaigns << [campaign, campaign2]

    # Make some test searches
    expect(search(company_id: company.id, current_company_user: user))
      .to match_array([event])

    expect(search(company_id: company.id, current_company_user: user,
                                          start_date: ['02/21/2013'], end_date: ['02/23/2013']))
      .to match_array([event])

    expect(search(company_id: company.id, current_company_user: user,
                                          start_date: ['02/21/2015'], end_date: ['02/23/2015']))
      .to match_array([])

    expect(search(company_id: company.id, current_company_user: user, campaign: [campaign.id],
                                          start_date: ['02/21/2013'], end_date: ['02/23/2013']))
      .to match_array([event])

  end

  it 'correctly search on the localized date fields', search: false, sunspot_matcher: true do
    Company.current = company
    described_class.do_search(company_id: company.id, start_date: ['01/01/2014'])
    d = Timeliness.parse('01/01/2014', zone: :current)
    expect(Sunspot.session).to have_search_params(:with) {
      all_of do
        with(:start_at).less_than(d.end_of_day)
        with(:end_at).greater_than(d.beginning_of_day)
      end
    }

    company.update_attribute :timezone_support, true
    described_class.do_search(company_id: company.id, start_date: ['01/01/2014'])
    d = Timeliness.parse('01/01/2014', zone: 'UTC')
    expect(Sunspot.session).to have_search_params(:with) {
      all_of do
        with(:local_start_at).less_than(d.end_of_day)
        with(:local_end_at).greater_than(d.beginning_of_day)
      end
    }
  end

  it 'returns the facets' do
    create(:event, campaign: campaign)
    Sunspot.commit
    s = described_class.do_search({ company_id: company.id }, true)
    expect(s.facet(:campaign_id).rows.map(&:value)).to eql [campaign.id]
    expect(s.facet(:place_id).rows.map(&:value)).to eql []
    expect(s.facet(:user_ids).rows.map(&:value)).to eql []
    expect(s.facet(:team_ids).rows.map(&:value)).to eql []
    expect(s.facet(:status).rows.map(&:value)).to eql [:active, :scheduled]
  end

  it 'returns only events with comments' do
    event1 = create(:event, company: company)
    event2 = create(:event, company: company)
    create(:comment, commentable: event1)
    expect(search(company_id: company.id)).to match_array([event1, event2])
    expect(search(company_id: company.id, with_comments_only: true)).to match_array([event1])
  end

  describe 'area customizations searches' do
    it 'should return events inside cities included to areas in campaigns' do
      place_la = create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      area_la = create(:area, company: company)
      city_la = create(:city, name: 'Los Angeles', country: 'US', state: 'California')

      area_campaign_la = create(:areas_campaign, area: area_la, campaign: campaign, inclusions: [city_la.id])

      event = create(:event, campaign: campaign, place: place_la)
      expect(search(company_id: company.id, area: [area_la.id])).to match_array [event]
      expect(search(company_id: company.id, q: "area,#{area_la.id}")).to match_array [event]
    end

    it 'should NOT return events inside cities excluded from areas in campaigns' do
      place_la = create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      place_sf = create(:place, country: 'US', state: 'California', city: 'San Francisco')
      area = create(:area, company: company)
      state = create(:state, name: 'California', country: 'US')
      city_la = create(:city, name: 'Los Angeles', country: 'US', state: 'California')

      area.places << state

      area_campaign = create(:areas_campaign, area: area, campaign: campaign)
      event1 = create(:event, campaign: campaign, place: place_la)
      event2 = create(:event, campaign: campaign, place: place_sf)

      expect(search(company_id: company.id, area: [area.id])).to match_array [event1, event2]

      area_campaign.update_column(:exclusions, [city_la.id])

      expect(search(company_id: company.id, area: [area.id])).to match_array [event2]
    end
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

    # Invalid brand
    expect(search(company_id: company.id, brand: 1))
      .to be_empty

    # Brand without campaings
    brand = create(:brand)
    expect(search(company_id: company.id, brand: brand.id))
      .to be_empty
  end
end
