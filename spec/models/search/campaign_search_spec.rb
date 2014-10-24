require 'rails_helper'

describe Campaign, type: :model, search: true do
  it 'should search for campaigns' do
    # First populate the Database with some data
    brand = create(:brand)
    brand2 = create(:brand)
    brand_portfolio = create(:brand_portfolio, company_id: 1, brand_ids: [brand.id])
    brand_portfolio2 = create(:brand_portfolio, company_id: 1, brand_ids: [brand.id, brand2.id])
    user = create(:company_user, company_id: 1)
    user2 = create(:company_user, company_id: 1)
    team = create(:team, company_id: 1)
    team2 = create(:team, company_id: 1)
    campaign = create(:campaign, company_id: 1, user_ids: [user.id], team_ids: [team.id],
                                 brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id])

    campaign2 = create(:campaign, company_id: 1, user_ids: [user.id, user2.id],
                                  team_ids: [team.id, team2.id],
                                  brand_portfolio_ids: [brand_portfolio.id, brand_portfolio2.id],
                                  brand_ids: [brand.id, brand2.id])

    # Create a Campaign on company 2
    company2_campaign = create(:campaign, company_id: 2)

    # Search for all Campaigns on a given Company
    expect(search(company_id: 1))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 2))
      .to match_array([company2_campaign])

    # Search for users associated to the Campaigns
    expect(search(company_id: 1, q: "user,#{user.id}"))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, q: "user,#{user2.id}"))
      .to match_array([campaign2])
    expect(search(company_id: 1, user: user.id))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, user: user2.id))
      .to match_array([campaign2])
    expect(search(company_id: 1, user: [user.id, user2.id]))
      .to match_array([campaign, campaign2])

    # Search for teams associated to the Campaigns
    expect(search(company_id: 1, q: "team,#{team.id}"))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, q: "team,#{team2.id}"))
      .to match_array([campaign2])
    expect(search(company_id: 1, team: team.id))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, team: team2.id))
      .to match_array([campaign2])
    expect(search(company_id: 1, team: [team.id, team2.id]))
      .to match_array([campaign, campaign2])

    # Search for brands associated to the Campaigns
    expect(search(company_id: 1, q: "brand,#{brand.id}"))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, q: "brand,#{brand2.id}"))
      .to match_array([campaign2])
    expect(search(company_id: 1, brand: brand.id))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, brand: brand2.id))
      .to match_array([campaign2])
    expect(search(company_id: 1, brand: [brand.id, brand2.id]))
      .to match_array([campaign, campaign2])

    # Search for brand portfolios associated to the Campaigns
    expect(search(company_id: 1, q: "brand_portfolio,#{brand_portfolio.id}"))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, q: "brand_portfolio,#{brand_portfolio2.id}"))
      .to match_array([campaign2])
    expect(search(company_id: 1, brand_portfolio: brand_portfolio.id))
      .to match_array([campaign, campaign2])
    expect(search(company_id: 1, brand_portfolio: brand_portfolio2.id))
      .to match_array([campaign2])
    expect(search(company_id: 1, brand_portfolio: [brand_portfolio.id, brand_portfolio2.id]))
      .to match_array([campaign, campaign2])

    # Search for a given Campaign
    expect(search({ company_id: 1, q: "campaign,#{campaign.id}" }, true))
      .to match_array([campaign])

    # Search for Campaigns on a given status
    expect(search(company_id: 1, status: ['Active']))
      .to match_array([campaign, campaign2])
  end
end
