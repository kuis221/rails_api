require 'rails_helper'

describe Team, type: :model, search: true do
  it 'should search for teams' do

    # First populate the Database with some data
    campaign = create(:campaign, company_id: 1)
    campaign2 = create(:campaign, company_id: 1)
    user = create(:company_user, company_id: 1)
    user2 = create(:company_user, company_id: 1)
    team = create(:team, campaign_ids: [campaign.id], user_ids: [user.id])
    team2 = create(:team, campaign_ids: [campaign.id, campaign2.id], user_ids: [user.id, user2.id])

    # Create a task on company 2
    company2_team = create(:team, company_id: 2)

    # Search for all Teams on a given Company
    expect(search(company_id: 1))
      .to match_array([team, team2])
    expect(search(company_id: 2))
      .to match_array([company2_team])

    # Search for users associated to the Teams
    expect(search(company_id: 1, q: "company_user,#{user.id}"))
      .to match_array([team, team2])
    expect(search(company_id: 1, q: "company_user,#{user2.id}"))
      .to match_array([team2])

    # Search for campaigns associated to the Teams
    expect(search(company_id: 1, q: "campaign,#{campaign.id}"))
      .to match_array([team, team2])
    expect(search(company_id: 1, q: "campaign,#{campaign2.id}"))
      .to match_array([team2])
    expect(search(company_id: 1, campaign: campaign.id))
      .to match_array([team, team2])
    expect(search(company_id: 1, campaign: campaign2.id))
      .to match_array([team2])
    expect(search(company_id: 1, campaign: [campaign.id, campaign2.id]))
      .to match_array([team, team2])

    # Search for a given Team
    expect(search({ company_id: 1, q: "team,#{team.id}" }, true))
      .to match_array([team])
    expect(search(company_id: 1, q: "team,#{team2.id}"))
      .to match_array([team2])

    # Search for Teams on a given status
    expect(search(company_id: 1, status: ['Active']))
      .to match_array([team, team2])
  end
end
