require 'rails_helper'

feature 'Tasks', js: true, search: true do
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company) { create(:company) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature 'video tutorial' do
    scenario 'a user can play and dismiss the video tutorial' do
      visit mine_tasks_path

      feature_name = 'GETTING STARTED: TASKS'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content('Tasks allow you to assign activities to other users')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit mine_tasks_path
      expect(page).to have_no_selector('h5', text: feature_name)
    end
  end

  feature '/tasks/mine' do
    scenario 'GET index should display a table with the tasks' do
      create(:task, title: 'Pick up kidz at school',
                    company_user: company_user, due_at: '2013-09-01', active: true,
                    event: create(:event, campaign: create(:campaign, name: 'Cacique FY14',
                                                                      company: company)))
      create(:task, title: 'Bring beers to the party',
                    company_user: company_user, due_at: '2013-09-02', active: true,
                    event: create(:event, campaign: create(:campaign, name: 'Centenario FY14',
                                                                      company: company)))
      Sunspot.commit
      visit mine_tasks_path

      within resource_item 1 do
        expect(page).to have_content('Pick up kidz at school')
        expect(page).to have_content('SUN Sep 1')
        expect(page).to have_content('Cacique FY14')
      end

      # Second Row
      within resource_item 2 do
        expect(page).to have_content('Bring beers to the party')
        expect(page).to have_content('MON Sep 2')
        expect(page).to have_content('Centenario FY14')
      end
    end

    scenario 'allows the user to activate/deactivate tasks' do
      event  = create(:event,
                      company: company,
                      campaign: create(:campaign,
                                       name: 'Cacique FY14',
                                       company: company))
      create(:task,
             title: 'Pick up kidz at school',
             company_user: company_user, due_at: '2013-09-01', active: true,
             event: event)
      Sunspot.commit

      visit mine_tasks_path

      within resource_item do
        click_js_link 'Deactivate'
      end

      confirm_prompt 'Are you sure you want to deactivate this task?'

      # Make it show only the inactive elements
      add_filter 'ACTIVE STATE', 'Inactive'
      remove_filter 'Active'

      expect(page).to have_content '1 task found for: Inactive'

      within resource_item do
        expect(page).to have_content('Pick up kidz at school')
        click_js_link 'Activate'
      end
      expect(page).to have_no_content('Pick up kidz at school')
    end

    it_behaves_like 'a list that allow saving custom filters' do

      before do
        create(:campaign, name: 'Campaign 1', company: company)
        create(:campaign, name: 'Campaign 2', company: company)
      end

      let(:list_url) { mine_tasks_path }

      let(:filters) do
        [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
         { section: 'CAMPAIGNS', item: 'Campaign 2' },
         { section: 'TASK STATUS', item: 'Complete' },
         { section: 'ACTIVE STATE', item: 'Inactive' }]
      end
    end

    feature 'tasks counters' do
      scenario 'filtering list will update the counters' do
        create(:late_task, company_user: company_user)
        create(:assigned_task, due_at: 1.week.from_now, company_user: company_user)
        create(:completed_task, company_user: company_user)
        create(:uncompleted_task, due_at: nil, company_user: company_user)

        Sunspot.commit

        visit mine_tasks_path

        expect(task_counters).to have_content '3INCOMPLETE'
        expect(task_counters).to have_content '1LATE'

        filter_section('TASK STATUS').unicheck 'Complete'

        expect(task_counters).to have_content '0INCOMPLETE'
        expect(task_counters).to have_content '0LATE'
      end
    end
  end

  scenario 'allows to create a new task' do
    visit mine_tasks_path

    click_js_button 'Add Task'
    within('form#new_task') do
      fill_in 'Title', with: 'Do the math homework'
      fill_in 'Due at', with: '05/16/2013'
      select_from_chosen('Test User', from: 'Assigned To')
      click_js_button 'Submit'
    end

    expect(page).to have_text('0INCOMPLETE')
    expect(page).to have_text('1LATE')

    within resource_item do
      expect(page).to have_content('Do the math homework')
      expect(page).to have_content('THU May 16')
    end
  end

  feature '/tasks/my_teams'  do
    scenario 'GET index should display a table with the tasks' do
      team1 = create(:team, company: company)
      team2 = create(:team, company: company)
      company_user.update_attributes(team_ids: [team1.id, team2.id])

      create(:task,
             title: 'User task',
             company_user: company_user, active: true,
             event: create(:event,
                           company: company,
                           campaign: create(:campaign,
                                            name: 'Cacique FY14', company: company)))

      team_tasks = [
        create(:task,
               title: 'Team task 1', due_at: '2013-09-01', active: true,
               event: create(:event, company: company, user_ids: [company_user.id],
                                     campaign: create(:campaign, name: 'Centenario FY14',
                                                                 company: company))),
        create(:task,
               title: 'Team task 2', due_at: nil, active: true,
               event: create(:event, company: company, team_ids: [team1.id],
                                     campaign: create(:campaign, name: 'Absolut FY13',
                                                                 company: company)))
      ]
      Sunspot.commit
      visit my_teams_tasks_path

      team_tasks.each do |task|
        # Find task Row
        within resource_item task, list: '#tasks-list' do
          expect(page).to have_content(task.title)
          expect(page).to have_content(task.event.campaign_name)
        end
      end
    end

    scenario 'GET index should display a table with the tasks I created' do
      assigned = create(:user, first_name: 'Juanito', last_name: 'Bazooka',
                               company: company, role_id: create(:role).id)

      task = create(:task,
                    title: 'Assigned user task', due_at: nil,
                    company_user: assigned.company_users.first, active: true,
                    event: create(:event,
                                  company: company,
                                  campaign: create(:campaign,
                                                   name: 'Cacique FY14', company: company)))

      task.update_attributes(created_by_id: company_user.id)

      Sunspot.commit
      visit my_teams_tasks_path

      within resource_item do
        expect(page).to have_content('Assigned user task')
        expect(page).to have_content('Cacique FY14')
        expect(page).to have_content('Juanito Bazooka')
      end
    end

    it_behaves_like 'a list that allow saving custom filters' do
      before do
        create(:campaign, name: 'Campaign 1', company: company)
        create(:campaign, name: 'Campaign 2', company: company)
      end

      let(:list_url) { my_teams_tasks_path }

      let(:filters) do
        [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
         { section: 'CAMPAIGNS', item: 'Campaign 2' },
         { section: 'STAFF', item: user.full_name },
         { section: 'TASK STATUS', item: 'Complete' },
         { section: 'ACTIVE STATE', item: 'Inactive' }]
      end
    end

    feature 'tasks counters' do
      scenario 'filtering list will update the counters' do
        event = create(:event, campaign: create(:campaign, company: company))
        team_member = create(:company_user, company: company)
        event.users << [team_member, company_user]
        create(:late_task, company_user: team_member, event: event)
        create(:assigned_task, due_at: 1.week.from_now, company_user: team_member, event: event)
        create(:completed_task, company_user: team_member, event: event)
        create(:uncompleted_task, due_at: nil, company_user: team_member, event: event)
        create(:unassigned_task, due_at: nil, event: event)

        Sunspot.commit

        visit my_teams_tasks_path

        expect(task_counters).to have_content '1UNASSIGNED'
        expect(task_counters).to have_content '4INCOMPLETE'
        expect(task_counters).to have_content '1LATE'

        add_filter 'TASK STATUS', 'Complete'

        expect(task_counters).to have_content '0UNASSIGNED'
        expect(task_counters).to have_content '0INCOMPLETE'
        expect(task_counters).to have_content '0LATE'

        remove_filter 'Complete'
        add_filter 'TASK STATUS', 'Incomplete'

        expect(task_counters).to have_content '1UNASSIGNED'
        expect(task_counters).to have_content '4INCOMPLETE'
        expect(task_counters).to have_content '1LATE'

        remove_filter 'Incomplete'
        add_filter 'TASK STATUS', 'Late'

        expect(task_counters).to have_content '0UNASSIGNED'
        expect(task_counters).to have_content '1INCOMPLETE'
        expect(task_counters).to have_content '1LATE'
      end
    end
  end

  feature 'export' do
    let!(:task1) do
      create(:task, title: 'Pick up kidz at school',
                    company_user: company_user, due_at: '2013-09-01', active: true,
                    event: create(:event, campaign: create(:campaign, name: 'Cacique FY14',
                                                                      company: company)))
    end
    let!(:task2) do
      create(:completed_task, title: 'Bring beers to the party',
                              company_user: company_user, due_at: '2013-09-02', active: true,
                              event: create(:event, campaign: create(:campaign, name: 'Centenario FY14',
                                                                                company: company)))
    end

    before { Sunspot.commit }

    scenario 'should be able to export as CSV' do
      visit mine_tasks_path

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      wait_for_export_to_complete

      expect(ListExport.last).to have_rows([
        %w(TITLE DATE CAMPAIGN STATUSES EMPLOYEE),
        ['Pick up kidz at school', '09/01/2013', 'Cacique FY14', 'Active Assigned Incomplete Late', 'Test User'],
        ['Bring beers to the party', '09/02/2013', 'Centenario FY14', 'Active Assigned Complete', 'Test User']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit mine_tasks_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      wait_for_export_to_complete

      # Test the generated PDF...
      reader = PDF::Reader.new(open(ListExport.last.file.url))
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include 'Pickupkidzatschool'
        expect(text).to include 'Bringbeerstotheparty'
        expect(text).to include 'CaciqueFY14'
        expect(text).to include 'CentenarioFY14'
        expect(text).to include 'SUNSep1,2013'
        expect(text).to include 'MONSep2,2013'
      end
    end

    scenario 'should not be able to export as PDF for documents with more than 200 pages' do
      allow(Task).to receive(:do_search).and_return(double(total: 3000))

      visit mine_tasks_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      within visible_modal do
        expect(page).to have_content('PDF exports are limited to 200 pages. Please narrow your results and try exporting again.')
        click_js_link 'OK'
      end
      ensure_modal_was_closed
    end
  end

  def task_counters
    find('.task-counter-bar')
  end

  def tasks_list
    '#tasks-list'
  end
end
