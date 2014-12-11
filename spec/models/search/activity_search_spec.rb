require 'rails_helper'

describe Activity, type: :model, search: true do
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
    place2 = create(:place, city: 'Chicago', state: 'Illinois', country: 'US')
    event = create(:event, campaign: campaign, place: place,
                           team_ids: [team.id], user_ids: [user3.id])
    event2 = create(:event, campaign: campaign2, place: place2,
                            team_ids: [team.id, team2.id], user_ids: [user3.id, user4.id])

    venue = event.venue
    venue2 = event2.venue

    area = create(:area, company: company)
    area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

    area2 = create(:area, company: company)
    area2.places << place

    # Create a Campaign and an Activity on company 2
    company2_campaign = create(:campaign)
    company2_event = create(:event, campaign: company2_campaign)

    activity_type1 = create(:activity_type, company: company, campaign_ids: [campaign.id])
    activity_type2 = create(:activity_type, company: company, campaign_ids: [campaign2.id])

    activity1 = create(:activity, activitable: event, campaign: campaign, company_user: user3,
                                  activity_type: activity_type1, activity_date: '02/22/2013')
    activity2 = create(:activity, activitable: event2, campaign: campaign2, company_user: user4,
                                  activity_type: activity_type2, activity_date: '03/22/2013')

    company2_activity = create(:activity,
                               activitable: company2_event,
                               campaign: company2_campaign,
                               company_user: create(:company_user, company: company2_campaign.company),
                               activity_type: create(:activity_type,
                                                     company: company2_campaign.company,
                                                     campaign_ids: [company2_campaign.id]))

    # Make some test searches

    # Search for all Activities on a given Company
    expect(search(company_id: company.id))
      .to match_array([activity1, activity2])
    expect(search(company_id: company2_campaign.company_id))
      .to match_array([company2_activity])

    # Search for a specific user's Activities
    expect(search(company_id: company.id, user: [user3.id]))
      .to match_array([activity1])
    expect(search(company_id: company.id, user: [user4.id]))
      .to match_array([activity2])
    expect(search(company_id: company.id, user: [user3.id, user4.id]))
      .to match_array([activity1, activity2])

    # Search for a specific Activity's venue
    expect(search(company_id: company.id, venue: [venue.id]))
      .to match_array([activity1])
    expect(search(company_id: company.id, venue: [venue2.id]))
      .to match_array([activity2])
    expect(search(company_id: company.id, venue: [venue.id, venue2.id]))
      .to match_array([activity1, activity2])

    # Search for a events in an area
    expect(search(company_id: company.id, area: [area.id]))
      .to match_array([activity1])
    expect(search(company_id: company.id, area: [area2.id]))
      .to match_array([activity1])

    # Search for brands associated to the Activities
    expect(search(company_id: company.id, brand: brand.id))
      .to match_array([activity1, activity2])
    expect(search(company_id: company.id, brand: brand2.id))
      .to match_array([activity2])
    expect(search(company_id: company.id, brand: [brand.id, brand2.id]))
      .to match_array([activity1, activity2])

    # Search for campaigns associated to the Activities
    expect(search(company_id: company.id, campaign: campaign.id))
      .to match_array([activity1])
    expect(search(company_id: company.id, campaign: campaign2.id))
      .to match_array([activity2])
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id]))
      .to match_array([activity1, activity2])

    # Search for Activities on a given date range
    expect(search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013'))
      .to match_array([activity1])
    expect(search(company_id: company.id, start_date: '02/22/2013'))
      .to match_array([activity1])
    expect(search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013'))
      .to match_array([activity2])
    expect(search(company_id: company.id, start_date: '03/22/2013'))
      .to match_array([activity2])
    expect(search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013'))
      .to be_empty

    # Search for Activities on a given status
    expect(search(company_id: company.id, status: ['Active']))
      .to match_array([activity1, activity2])
  end
end
