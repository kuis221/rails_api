require 'spec_helper'

feature "Tasks", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    @company_user = @user.company_users.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  feature "/tasks/mine"  do
    scenario "GET index should display a table with the events" do
      tasks = [
        FactoryGirl.create(:task, title: 'Pick up kidz at school', company_user: @company_user, due_at: '2013-09-01', active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Cacique FY14', company: @company))),
        FactoryGirl.create(:task, title: 'Bring beers to the party', company_user: @company_user, due_at: '2013-09-02' , active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Centenario FY14', company: @company)))
      ]
      Sunspot.commit
      visit mine_tasks_path

      within("ul#tasks-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Pick up kidz at school')
          expect(page).to have_content('SUN Sep 1')
          expect(page).to have_content('Cacique FY14')
        end

        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Bring beers to the party')
          expect(page).to have_content('MON Sep 2')
          expect(page).to have_content('Centenario FY14')
        end
      end
    end

    scenario "allows the user to activate/deactivate tasks" do
      FactoryGirl.create(:task,
        title: 'Pick up kidz at school',
        company_user: @company_user, due_at: '2013-09-01', active: true,
        event: FactoryGirl.create(:event, company: @company,
          campaign: FactoryGirl.create(:campaign, name: 'Cacique FY14', company: @company)))
      Sunspot.commit
      visit mine_tasks_path

      within("ul#tasks-list li:nth-child(1)") do
        click_js_link 'Deactivate'
      end

      confirm_prompt 'Are you sure you want to deactivate this task?'

      filter_section('ACTIVE STATE').unicheck('Active')
      filter_section('ACTIVE STATE').unicheck('Inactive')
      within "ul#tasks-list li:nth-child(1)" do
        expect(page).to have_content('Pick up kidz at school')
        click_js_link 'Activate'
      end
      within "ul#tasks-list" do
        expect(page).to have_no_content('Pick up kidz at school')
      end
    end
  end

  scenario "allows to create a new task" do
    visit mine_tasks_path

    click_js_button 'Create'
    within('form#new_task') do
      fill_in 'Title', with: 'Do the math homework'
      fill_in 'Due at', with: '05/16/2013'
      select_from_chosen('Test User', :from => 'Assigned To')
      click_js_button 'Submit'
    end

    expect(page).to have_text('0 INCOMPLETE')
    expect(page).to have_text('1 LATE')

    within('#tasks-list li') do
      expect(page).to have_content('Do the math homework')
      expect(page).to have_content('THU May 16')
    end
  end

  feature "/tasks/my_teams"  do
    scenario "GET index should display a table with the events" do
      team1 = FactoryGirl.create(:team, company: @company)
      team2 = FactoryGirl.create(:team, company: @company)
      @company_user.update_attributes({:team_ids => [team1.id, team2.id]}, without_protection: true)


      user_task = FactoryGirl.create(:task, title: 'User task', company_user: @company_user , active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Cacique FY14', company: @company)))

      team_tasks = [
        FactoryGirl.create(:task, title: 'Team task 1', due_at: '2013-09-01', active: true, event: FactoryGirl.create(:event, company: @company, user_ids: [@company_user.id], campaign: FactoryGirl.create(:campaign, name: 'Centenario FY14', company: @company))),
        FactoryGirl.create(:task, title: 'Team task 2', due_at: nil, active: true, event: FactoryGirl.create(:event, company: @company, team_ids: [team1.id], campaign: FactoryGirl.create(:campaign, name: 'Absolut FY13', company: @company)))
      ]
      Sunspot.commit
      visit my_teams_tasks_path

      within("ul#tasks-list") do
        team_tasks.each do |task|
          # Find task Row
          within("li#task_#{task.id}") do
            expect(page).to have_content(task.title)
            expect(page).to have_content(task.event.campaign_name)
          end
        end
      end
    end
  end
end