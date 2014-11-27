require 'rails_helper'

describe Task, type: :model, search: true do
  it 'should search for tasks' do

    # First populate the Database with some data
    company = create(:company)
    campaign = create(:campaign, company: company)
    campaign2 = create(:campaign, company: company)
    event = create(:event, company: company, campaign: campaign)
    event2 = create(:event, company: company, campaign: campaign2)
    team = create(:team, company: company)
    team2 = create(:team, company: company)
    user = create(:company_user, company: company, team_ids: [team.id], role: create(:role))
    user_tasks = create_list(:task, 2, due_at: Time.new(2013, 02, 22, 12, 00, 00), company_user: user, event: event)

    user2 = create(:company_user, company: company, team_ids: [team.id, team2.id], role: create(:role))
    user2_tasks = create_list(:task, 2, due_at: Time.new(2013, 03, 22, 12, 00, 00), company_user: user2, event: event2)

    # Create a task on company 2
    company2 = create(:company)
    company2_task = create(:task, company_user: create(:company_user, company_id: 2), event: create(:event, company: company2))

    # Make some test searches

    # Search for tasks by id
    expect(search(company_id: company.id, id: user_tasks.map(&:id)))
      .to match_array(user_tasks)
    expect(search(company_id: company.id, id: user2_tasks.map(&:id)))
      .to match_array(user2_tasks)
    expect(search(company_id: company.id, id: user_tasks.first.id))
      .to match_array([user_tasks.first])

    # Search for all tasks on a given company
    expect(search(company_id: company.id))
      .to match_array(user_tasks + user2_tasks)
    expect(search(company_id: company2.id))
      .to match_array([company2_task])

    expect(search(company_id: company.id, team: [team.id]))
      .to match_array(user_tasks + user2_tasks)
    expect(search(company_id: company.id, team: [team2.id]))
      .to match_array(user2_tasks)

    # Search for a specific user's tasks
    expect(search(company_id: company.id, user: user.id))
      .to match_array(user_tasks)
    expect(search(company_id: company.id, user: user2.id))
      .to match_array(user2_tasks)
    expect(search(company_id: company.id, user: [user.id, user2.id]))
      .to match_array(user_tasks + user2_tasks)

    # Search for a specific event's tasks
    expect(search(company_id: company.id, event_id: event.id))
      .to match_array(user_tasks)
    expect(search(company_id: company.id, event_id: event2.id))
      .to match_array(user2_tasks)
    expect(search(company_id: company.id, event_id: [event.id, event2.id]))
      .to match_array(user_tasks + user2_tasks)

    # Search for a campaign's tasks
    expect(search(company_id: company.id, campaign: campaign.id))
      .to match_array(user_tasks)
    expect(search(company_id: company.id, campaign: campaign2.id))
      .to match_array(user2_tasks)
    expect(search(company_id: company.id, campaign: [campaign.id, campaign2.id]))
      .to match_array(user_tasks + user2_tasks)

    # Search for a given task
    task = user_tasks.first
    expect(search(company_id: company.id, task: task.id))
      .to match_array([task])

    # Search for tasks on a given date range
    expect(search(company_id: company.id, start_date: '02/21/2013', end_date: '02/23/2013'))
      .to match_array(user_tasks)
    expect(search(company_id: company.id, start_date: '02/22/2013'))
      .to match_array(user_tasks)
    expect(search(company_id: company.id, start_date: '03/21/2013', end_date: '03/23/2013'))
      .to match_array(user2_tasks)
    expect(search(company_id: company.id, start_date: '03/22/2013'))
      .to match_array(user2_tasks)
    expect(search(company_id: company.id, start_date: '01/21/2013', end_date: '01/23/2013')).to eq([])

    # Search for Events on a given Event
    expect(search(company_id: company.id, status: ['Active']))
      .to match_array(user_tasks + user2_tasks)
  end

  it 'should search for the :task_status params' do
    company = create(:company)
    user = create(:company_user, company: company)
    event     = create(:event, company: company)
    late_task = create(:late_task, event: event)
    future_task = create(:future_task, event: event)
    assigned_and_late_task = create(:assigned_task, company_user: user, event: event,
                                    due_at: 3.weeks.ago)
    assigned_and_in_future_task = create(:assigned_task,
                                         company_user: user,
                                         event: event, due_at: 3.weeks.from_now)
    unassigned_task = create(:unassigned_task, event: event, due_at: 3.weeks.from_now)
    completed_task = create(:completed_task, company_user: user,  event: event)

    expect(search(company_id: company.id, task_status: ['Late']))
        .to match_array([late_task, assigned_and_late_task])

    expect(search(company_id: company.id, task_status: %w(Late Complete)))
        .to match_array([late_task, assigned_and_late_task, completed_task])

    expect(search(company_id: company.id, task_status: ['Complete']))
        .to match_array([completed_task])

    expect(search(company_id: company.id, task_status: ['Incomplete']))
        .to match_array([late_task, future_task, assigned_and_late_task, assigned_and_in_future_task, unassigned_task])

    expect(search(company_id: company.id, task_status: ['Assigned']))
        .to match_array([assigned_and_late_task, assigned_and_in_future_task, completed_task])

    expect(search(company_id: company.id, task_status: ['Unassigned']))
        .to match_array([late_task, future_task, unassigned_task])
  end
end
