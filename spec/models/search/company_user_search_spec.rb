
require 'rails_helper'

describe CompanyUser, type: :model, search: true do
  it 'should search for tasks' do
    # First populate the Database with some data
    campaign = create(:campaign, company_id: 1)
    campaign2 = create(:campaign, company_id: 1)
    team = create(:team)
    team2 = create(:team)
    user = create(:company_user, company_id: 1, active: false, team_ids: [team.id],
                                 role: create(:role, company_id: 1))
    user2 = create(:company_user, company_id: 1, active: false, team_ids: [team.id, team2.id],
                                  role: create(:role, company_id: 1))
    user2_in_company2 = create(:company_user, company_id: 2, user: user2.user,
                                  role: create(:role, company_id: 2))
    user.campaigns << campaign
    user2.campaigns << campaign2
    user.solr_index
    user2.solr_index

    # Search for all tasks on a given company
    expect(search(company_id: 1))
      .to match_array([user, user2])
    expect(search(company_id: 2))
      .to match_array([user2_in_company2])


    # Search for a specific users
    expect(search(company_id: 1, user: [user.id]))
      .to match_array([user])
    expect(search(company_id: 1, user: [user2.id]))
      .to match_array([user2])

    # Search for users with a specific role
    expect(search(company_id: 1, role: user.role_id))
      .to match_array([user])
    expect(search(company_id: 1, role: user2.role_id))
      .to match_array([user2])
    expect(search(company_id: 1, role: [user.role_id, user2.role_id]))
      .to match_array([user, user2])

    # Search for a campaign's tasks
    expect(search(company_id: 1, campaign: campaign.id))
      .to match_array([user])
    expect(search(company_id: 1, campaign: campaign2.id))
      .to match_array([user2])
    expect(search(company_id: 1, campaign: [campaign.id, campaign2.id]))
      .to match_array([user, user2])

    # Search for users with a specific team
    expect(search(company_id: 1, team: team.id))
      .to match_array([user, user2])
    expect(search(company_id: 1, team: team2.id))
      .to match_array([user2])
    expect(search(company_id: 1, team: [team.id, team2.id]))
      .to match_array([user, user2])
  end
end
