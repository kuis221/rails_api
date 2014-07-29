require 'spec_helper'

describe Campaign, type: :model, search: true do
  it "should search for campaigns" do
    # First populate the Database with some data
    brand = FactoryGirl.create(:brand)
    brand2 = FactoryGirl.create(:brand)
    brand_portfolio = FactoryGirl.create(:brand_portfolio, company_id: 1, brand_ids: [brand.id])
    brand_portfolio2 = FactoryGirl.create(:brand_portfolio, company_id: 1, brand_ids: [brand.id, brand2.id])
    user = FactoryGirl.create(:company_user, company_id: 1)
    user2 = FactoryGirl.create(:company_user, company_id: 1)
    team = FactoryGirl.create(:team, company_id: 1)
    team2 = FactoryGirl.create(:team, company_id: 1)
    campaign = FactoryGirl.create(:campaign, company_id: 1, user_ids: [user.id], team_ids: [team.id], brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id])
    campaign2 = FactoryGirl.create(:campaign, company_id: 1, user_ids: [user.id, user2.id], team_ids: [team.id, team2.id], brand_portfolio_ids: [brand_portfolio.id, brand_portfolio2.id], brand_ids: [brand.id, brand2.id])

    # Create a Campaign on company 2
    company2_campaign = FactoryGirl.create(:campaign, company_id: 2)

    Sunspot.commit

    # Search for all Campaigns on a given Company
    expect(Campaign.do_search(company_id: 1).results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 2).results).to match_array([company2_campaign])

    # Search for users associated to the Campaigns
    expect(Campaign.do_search(company_id: 1, q: "user,#{user.id}").results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, q: "user,#{user2.id}").results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, user: user.id).results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, user: user2.id).results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, user: [user.id, user2.id]).results).to match_array([campaign, campaign2])

    # Search for teams associated to the Campaigns
    expect(Campaign.do_search(company_id: 1, q: "team,#{team.id}").results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, q: "team,#{team2.id}").results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, team: team.id).results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, team: team2.id).results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, team: [team.id, team2.id]).results).to match_array([campaign, campaign2])

    # Search for brands associated to the Campaigns
    expect(Campaign.do_search(company_id: 1, q: "brand,#{brand.id}").results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, q: "brand,#{brand2.id}").results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, brand: brand.id).results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, brand: brand2.id).results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, brand: [brand.id, brand2.id]).results).to match_array([campaign, campaign2])

    # Search for brand portfolios associated to the Campaigns
    expect(Campaign.do_search(company_id: 1, q: "brand_portfolio,#{brand_portfolio.id}").results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, q: "brand_portfolio,#{brand_portfolio2.id}").results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, brand_portfolio: brand_portfolio.id).results).to match_array([campaign, campaign2])
    expect(Campaign.do_search(company_id: 1, brand_portfolio: brand_portfolio2.id).results).to match_array([campaign2])
    expect(Campaign.do_search(company_id: 1, brand_portfolio: [brand_portfolio.id, brand_portfolio2.id]).results).to match_array([campaign, campaign2])

    # Search for a given Campaign
    expect(Campaign.do_search({company_id: 1, q: "campaign,#{campaign.id}"}, true).results).to match_array([campaign])

    # Search for Campaigns on a given status
    expect(Campaign.do_search(company_id: 1, status: ['Active']).results).to match_array([campaign, campaign2])
  end
end