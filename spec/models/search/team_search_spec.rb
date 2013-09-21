require 'spec_helper'

describe Team, search: true do
  it "should search for teams" do

    # First populate the Database with some data
    campaign = FactoryGirl.create(:campaign, company_id: 1)
    campaign2 = FactoryGirl.create(:campaign, company_id: 1)
    user = FactoryGirl.create(:company_user, company_id: 1)
    user2 = FactoryGirl.create(:company_user, company_id: 1)
    team = FactoryGirl.create(:team, campaign_ids: [campaign.id], user_ids: [user.id])
    team2 = FactoryGirl.create(:team, campaign_ids: [campaign.id, campaign2.id], user_ids: [user.id, user2.id])

    # Create a task on company 2
    company2_team = FactoryGirl.create(:team, company_id: 2)

    Sunspot.commit

    # Search for all Teams on a given Company
    Team.do_search(company_id: 1).results.should =~ [team, team2]
    Team.do_search(company_id: 2).results.should =~ [company2_team]

    # Search for users associated to the Teams
    Team.do_search(company_id: 1, q: "company_user,#{user.id}").results.should =~ [team, team2]
    Team.do_search(company_id: 1, q: "company_user,#{user2.id}").results.should =~ [team2]

    # Search for campaigns associated to the Teams
    Team.do_search(company_id: 1, q: "campaign,#{campaign.id}").results.should =~ [team, team2]
    Team.do_search(company_id: 1, q: "campaign,#{campaign2.id}").results.should =~ [team2]
    Team.do_search(company_id: 1, campaign: campaign.id).results.should =~ [team, team2]
    Team.do_search(company_id: 1, campaign: campaign2.id).results.should =~ [team2]
    Team.do_search(company_id: 1, campaign: [campaign.id, campaign2.id]).results.should =~ [team, team2]

    # Search for a given Team
    Team.do_search({company_id: 1, q: "team,#{team.id}"}, true).results.should =~ [team]
    Team.do_search(company_id: 1, q: "team,#{team2.id}").results.should =~ [team2]

    # Search for Teams on a given status
    Team.do_search(company_id: 1, status: ['Active']).results.should =~ [team, team2]
  end
end