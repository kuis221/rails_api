require 'rails_helper'

describe BrandAmbassadors::Visit, type: :model, search: true do
  after do
    Timecop.return
  end

  it "should search for visits" do
    company = FactoryGirl.create(:company)
    # First populate the Database with some data
    campaign = FactoryGirl.create(:campaign, company: company)
    campaign2 = FactoryGirl.create(:campaign, company: company)
    team = FactoryGirl.create(:team, company: company)
    team2 = FactoryGirl.create(:team, company: company)
    user = FactoryGirl.create(:company_user, company: company, team_ids: [team.id], role: FactoryGirl.create(:role, company: company))
    user2 = FactoryGirl.create(:company_user, company: company, team_ids: [team.id, team2.id], role: FactoryGirl.create(:role, company: company))
    user3 = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, company: company))
    user4 = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, company: company))
    place = FactoryGirl.create(:place, city: 'Los Angeles', state: 'California', country: 'US')
    place2 = FactoryGirl.create(:place, city: 'Chicago')


    area = FactoryGirl.create(:area, company: company)
    area.places << FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')

    area2 = FactoryGirl.create(:area, company: company)
    area2.places << place

    visit = FactoryGirl.create(:brand_ambassadors_visit, company: company,
      company_user: user3, area: area, campaign: campaign, city: 'Los Angeles',
      start_date: "02/22/2013", end_date: "02/23/2013")
    visit2 = FactoryGirl.create(:brand_ambassadors_visit, company: company,
      company_user: user4, area: area2, campaign: campaign2, city: 'San Jose',
      start_date: "03/22/2013", end_date: "03/22/2013")


    # Create a Campaign and an Event on company 2
    company2_campaign = FactoryGirl.create(:campaign)
    company2_visit = FactoryGirl.create(:brand_ambassadors_visit, company: company2_campaign.company)

    # Inactive visit should never be returned
    FactoryGirl.create(:brand_ambassadors_visit, company: company, active: false)

    Sunspot.commit

    # Make some test searches

    # Search for all Visits on a given Company
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id).results).to match_array([visit, visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company2_campaign.company_id).results).to match_array([company2_visit])

    # Search for a specific user's Visits
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, q: "company_user,#{user3.id}").results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, q: "company_user,#{user4.id}").results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, user: [user3.id]).results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, user: [user4.id]).results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, user: [user3.id,user4.id]).results).to match_array([visit, visit2])

    # Search for a visits in an area
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, q: "area,#{area.id}").results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, area: [area.id]).results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, q: "area,#{area2.id}").results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, area: [area2.id]).results).to match_array([visit2])


    # Search for a visits in a city
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, city: ['Los Angeles']).results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, city: ['San Jose']).results).to match_array([visit2])

    # Search for campaigns associated to the Visits
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, q: "campaign,#{campaign.id}").results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, q: "campaign,#{campaign2.id}").results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, campaign: campaign.id).results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, campaign: campaign2.id).results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, campaign: [campaign.id, campaign2.id]).results).to match_array([visit, visit2])

    # Search for Visits on a given date range
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013').results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, start_date: '02/22/2013').results).to match_array([visit])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013').results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, start_date: '03/22/2013').results).to match_array([visit2])
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013').results).to eq([])

  end

  it "should not fail if a brand without campaings is given" do
    company = FactoryGirl.create(:company)
    FactoryGirl.create(:event, company: company)

    Sunspot.commit
    # Invalid brand
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, brand: 1).results).to match_array([])

    # Brand without campaings
    brand = FactoryGirl.create(:brand)
    expect(BrandAmbassadors::Visit.do_search(company_id: company.id, brand: brand.id).results).to match_array([])
  end
end
