
require 'spec_helper'

describe CompanyUser, type: :model, search: true do
  it "should search for tasks" do

    # First populate the Database with some data
    campaign = FactoryGirl.create(:campaign, company_id: 1)
    campaign2 = FactoryGirl.create(:campaign, company_id: 1)
    team = FactoryGirl.create(:team)
    team2 = FactoryGirl.create(:team)
    user = FactoryGirl.create(:company_user, company_id: 1, active: false, team_ids: [team.id], role: FactoryGirl.create(:role, company_id: 1))
    user2 = FactoryGirl.create(:company_user, company_id: 1, active: false, team_ids: [team.id, team2.id], role: FactoryGirl.create(:role, company_id: 1))
    user2_in_company2 = FactoryGirl.create(:company_user, company_id: 2, user: user2.user, role: FactoryGirl.create(:role, company_id: 2))
    user.campaigns << campaign
    user2.campaigns << campaign2
    user.solr_index
    user2.solr_index
    Sunspot.commit

    # Make some test searches

    # Search for all tasks on a given company
    expect(CompanyUser.do_search(company_id: 1).results).to match_array([user, user2])
    expect(CompanyUser.do_search(company_id: 2).results).to match_array([user2_in_company2])

    expect(CompanyUser.do_search({company_id: 1, q: "team,#{team.id}"}, true).results).to match_array([user, user2])
    expect(CompanyUser.do_search(company_id: 1, q: "team,#{team2.id}").results).to match_array([user2])

    # Search for a specific users
    expect(CompanyUser.do_search(company_id: 1, q: "company_user,#{user.id}").results).to match_array([user])
    expect(CompanyUser.do_search(company_id: 1, q: "company_user,#{user2.id}").results).to match_array([user2])

    # Search for users with a specific role
    expect(CompanyUser.do_search(company_id: 1, q: "role,#{user.role_id}").results).to match_array([user])
    expect(CompanyUser.do_search(company_id: 1, q: "role,#{user2.role_id}").results).to match_array([user2])
    expect(CompanyUser.do_search(company_id: 1, role: user.role_id).results).to match_array([user])
    expect(CompanyUser.do_search(company_id: 1, role: user2.role_id).results).to match_array([user2])
    expect(CompanyUser.do_search(company_id: 1, role: [user.role_id, user2.role_id]).results).to match_array([user, user2])

    # Search for a campaign's tasks
    expect(CompanyUser.do_search(company_id: 1, q: "campaign,#{campaign.id}").results).to match_array([user])
    expect(CompanyUser.do_search(company_id: 1, q: "campaign,#{campaign2.id}").results).to match_array([user2])
    expect(CompanyUser.do_search(company_id: 1, campaign: campaign.id).results).to match_array([user])
    expect(CompanyUser.do_search(company_id: 1, campaign: campaign2.id).results).to match_array([user2])
    expect(CompanyUser.do_search(company_id: 1, campaign: [campaign.id, campaign2.id]).results).to match_array([user, user2])

    # Search for users with a specific team
    expect(CompanyUser.do_search(company_id: 1, team: team.id).results).to match_array([user, user2])
    expect(CompanyUser.do_search(company_id: 1, team: team2.id).results).to match_array([user2])
    expect(CompanyUser.do_search(company_id: 1, team: [team.id, team2.id]).results).to match_array([user, user2])

  end
end