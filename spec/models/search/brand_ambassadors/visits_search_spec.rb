require 'rails_helper'

describe BrandAmbassadors::Visit, type: :model, search: true do
  after do
    Timecop.return
  end

  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }

  it 'should search for visits' do
    # First populate the Database with some data
    campaign2 = create(:campaign, company: company)
    team = create(:team, company: company)
    team2 = create(:team, company: company)
    create(:company_user, company: company, team_ids: [team.id], role: create(:role, company: company))
    create(:company_user, company: company, team_ids: [team.id, team2.id], role: create(:role, company: company))
    user3 = create(:company_user, company: company, role: create(:role, company: company))
    user4 = create(:company_user, company: company, role: create(:role, company: company))
    place = create(:place, city: 'Los Angeles', state: 'California', country: 'US')
    create(:place, city: 'Chicago')

    area = create(:area, company: company)
    area.places << create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')

    area2 = create(:area, company: company)
    area2.places << place

    visit = create(:brand_ambassadors_visit, company: company,
      company_user: user3, area: area, campaign: campaign, city: 'Los Angeles',
      start_date: '02/22/2013', end_date: '02/23/2013')
    visit2 = create(:brand_ambassadors_visit, company: company,
      company_user: user4, area: area2, campaign: campaign2, city: 'San Jose',
      start_date: '03/22/2013', end_date: '03/22/2013')

    # Create a Campaign and an Event on company 2
    company2_campaign = create(:campaign)
    company2_visit = create(:brand_ambassadors_visit, company: company2_campaign.company)

    # Inactive visit should never be returned
    create(:brand_ambassadors_visit, company: company, active: false)

    # Make some test searches

    # Search for all Visits on a given Company
    expect(search(company_id: company.id)).to match_array([visit, visit2])
    expect(search(company_id: company2_campaign.company_id)).to match_array([company2_visit])

    # Search for a specific user's Visits
    expect(search(company_id: company.id, q: "company_user,#{user3.id}")).to match_array([visit])
    expect(search(company_id: company.id, q: "company_user,#{user4.id}")).to match_array([visit2])
    expect(search(company_id: company.id, user: [user3.id])).to match_array([visit])
    expect(search(company_id: company.id, user: [user4.id])).to match_array([visit2])
    expect(search(company_id: company.id, user: [user3.id, user4.id])).to match_array([visit, visit2])

    # Search for a visits in an area
    expect(search(company_id: company.id, q: "area,#{area.id}")).to match_array([visit])
    expect(search(company_id: company.id, area: [area.id])).to match_array([visit])
    expect(search(company_id: company.id, q: "area,#{area2.id}")).to match_array([visit2])
    expect(search(company_id: company.id, area: [area2.id])).to match_array([visit2])

    # Search for a visits in a city
    expect(search(company_id: company.id, city: ['Los Angeles'])).to match_array([visit])
    expect(search(company_id: company.id, city: ['San Jose'])).to match_array([visit2])

    # Search for campaigns associated to the Visits
    expect(search(company_id: company.id, q: "campaign,#{campaign.id}")).to match_array([visit])
    expect(search(company_id: company.id, q: "campaign,#{campaign2.id}")).to match_array([visit2])
    expect(search(company_id: company.id, campaign: campaign.id)).to match_array([visit])
    expect(search(company_id: company.id, campaign: campaign2.id)).to match_array([visit2])
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id])).to match_array([visit, visit2])

    # Search for Visits on a given date range
    expect(search(company_id: company.id, start_date: ['02/21/2013'], end_date: ['02/23/2013'])).to match_array([visit])
    expect(search(company_id: company.id, start_date: ['02/22/2013'])).to match_array([visit])
    expect(search(company_id: company.id, start_date: ['03/21/2013'], end_date: ['03/23/2013'])).to match_array([visit2])
    expect(search(company_id: company.id, start_date: ['03/22/2013'])).to match_array([visit2])
    expect(search(company_id: company.id, start_date: ['01/21/2013'], end_date: ['01/23/2013'])).to eq([])
  end

  it 'returns only results accessible for the current user' do
    user = create(:company_user, company: company, role: create(:non_admin_role, company: company))
    area = create(:area, company: company)
    city = create(:city, name: 'Los Angeles')
    user.places << city
    user.campaigns << campaign
    area.places << city

    visit = create(:brand_ambassadors_visit, company: company,
      area: area, campaign: campaign, city: 'Los Angeles')
    visit_without_area = create(:brand_ambassadors_visit, company: company,
      area: nil, campaign: campaign, city: nil)

    # A visit in an area not in user's list
    create(:brand_ambassadors_visit, company: company,
      area: create(:area, company: company),
      campaign: campaign, city: nil)

    # A visit in an area not in user's campaign list
    create(:brand_ambassadors_visit, company: company,
      area: area, campaign: create(:campaign, company: company), city: nil)

    expect(search(company_id: company.id, current_company_user: user))
        .to match_array([visit, visit_without_area])
  end

  it 'return visits that are inside the user geographic permissions' do
    user = create(:company_user, company: company, role: create(:non_admin_role, company: company))
    area = create(:area, company: company)

    visit = create(:brand_ambassadors_visit, company: company,
      area: area, campaign: campaign, city: nil)

    area.places << create(:city, name: 'Los Angeles', state: 'California')
    user.places << create(:country, name: 'United States')
    user.campaigns << campaign

    expect(search(company_id: company.id, current_company_user: user))
        .to match_array([visit])
  end

  it 'return visits without area' do
    user = create(:company_user, company: company, role: create(:non_admin_role, company: company))

    visit = create(:brand_ambassadors_visit, company: company,
      area: nil, campaign: campaign, city: nil)
    user.campaigns << campaign

    expect(search(company_id: company.id, current_company_user: user))
        .to match_array([visit])
  end

  it 'not fail if a brand without campaings is given' do
    create(:event, company: company)

    # Invalid brand
    expect(search(company_id: company.id, brand: 1)).to match_array([])

    # Brand without campaings
    brand = create(:brand)
    expect(search(company_id: company.id, brand: brand.id)).to match_array([])
  end
end
