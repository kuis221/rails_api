
require 'spec_helper'

describe Task, search: true do
  it "should search for tasks" do

    # First populate the Database with some data
    campaign = FactoryGirl.create(:campaign, company_id: 1)
    campaign2 = FactoryGirl.create(:campaign, company_id: 1)
    event = FactoryGirl.create(:event, company_id: 1, campaign: campaign)
    event2 = FactoryGirl.create(:event, company_id: 1, campaign: campaign2)
    team = FactoryGirl.create(:team)
    team2 = FactoryGirl.create(:team)
    user = FactoryGirl.create(:company_user, company_id: 1, team_ids: [team.id], role: FactoryGirl.create(:role))
    user_tasks = FactoryGirl.create_list(:task, 2, due_at: Time.new(2013, 02, 22, 12, 00, 00), company_user: user, event: event)

    user2 = FactoryGirl.create(:company_user, company_id: 1, team_ids: [team.id, team2.id], role: FactoryGirl.create(:role))
    user2_tasks = FactoryGirl.create_list(:task, 2, due_at: Time.new(2013, 03, 22, 12, 00, 00), company_user: user2, event: event2)

    # Create a task on company 2
    company2_task = FactoryGirl.create(:task, company_user: FactoryGirl.create(:company_user, company_id: 2), event: FactoryGirl.create(:event, company_id: 2))

    Sunspot.commit

    # Make some test searches

    # Search for all tasks on a given company
    Task.do_search(company_id: 1).results.should =~ user_tasks + user2_tasks
    Task.do_search(company_id: 2).results.should =~ [company2_task]

    Task.do_search(company_id: 1, q: "team,#{team.id}").results.should =~ user_tasks + user2_tasks
    Task.do_search(company_id: 1, q: "team,#{team2.id}").results.should =~ user2_tasks

    # Search for a specific user's tasks
    Task.do_search(company_id: 1, q: "companyuser,#{user.id}").results.should =~ user_tasks
    Task.do_search(company_id: 1, q: "companyuser,#{user2.id}").results.should =~ user2_tasks
    Task.do_search(company_id: 1, user: user.id).results.should =~ user_tasks
    Task.do_search(company_id: 1, user: user2.id).results.should =~ user2_tasks
    Task.do_search(company_id: 1, user: [user.id,user2.id]).results.should =~ user_tasks + user2_tasks

    # Search for a specific event's tasks
    Task.do_search(company_id: 1, event_id: event.id).results.should =~ user_tasks
    Task.do_search(company_id: 1, event_id: event2.id).results.should =~ user2_tasks
    Task.do_search(company_id: 1, event_id: [event.id, event2.id]).results.should =~ user_tasks + user2_tasks

    # Search for a campaign's tasks
    Task.do_search(company_id: 1, q: "campaign,#{campaign.id}").results.should =~ user_tasks
    Task.do_search(company_id: 1, q: "campaign,#{campaign2.id}").results.should =~ user2_tasks
    Task.do_search(company_id: 1, campaign: campaign.id).results.should =~ user_tasks
    Task.do_search(company_id: 1, campaign: campaign2.id).results.should =~ user2_tasks
    Task.do_search(company_id: 1, campaign: [campaign.id, campaign2.id]).results.should =~ user_tasks + user2_tasks

    # Search for a given task
    task = user_tasks.first
    Task.do_search(company_id: 1, q: "task,#{task.id}").results.should =~ [task]

    # Search for tasks on a given date range
    Task.do_search(company_id: 1, start_date: '02/21/2013', end_date: '02/23/2013').results.should =~ user_tasks
    Task.do_search(company_id: 1, start_date: '02/22/2013').results.should =~ user_tasks

    Task.do_search(company_id: 1, start_date: '03/21/2013', end_date: '03/23/2013').results.should =~ user2_tasks
    Task.do_search(company_id: 1, start_date: '03/22/2013').results.should =~ user2_tasks

    Task.do_search(company_id: 1, start_date: '01/21/2013', end_date: '01/23/2013').results.should == []
  end
end