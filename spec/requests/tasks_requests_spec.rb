require 'spec_helper'

describe "Tasks", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    @company_user = @user.company_users.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  describe "/tasks/mine"  do
    it "GET index should display a table with the events" do
      tasks = [
        FactoryGirl.create(:task, title: 'Pick up kidz at school', company_user: @company_user , active: true, event: FactoryGirl.create(:event)),
        FactoryGirl.create(:task, title: 'Bring beers to the party', company_user: @company_user , active: true, event: FactoryGirl.create(:event))
      ]
      Sunspot.commit
      visit mine_tasks_path

      within("table#tasks-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Bring beers to the party')
          find('td:nth-child(4)').should have_content(@user.full_name)
          find('td:nth-child(6)').should have_content('Edit')
          find('td:nth-child(6)').should have_content('Deactivate')
          find('td:nth-child(6)').should have_content('Comment')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('Pick up kidz at school')
          find('td:nth-child(4)').should have_content(@user.full_name)
          find('td:nth-child(6)').should have_content('Edit')
          find('td:nth-child(6)').should have_content('Deactivate')
          find('td:nth-child(6)').should have_content('Comment')
        end

      end

      assert_table_sorting ("table#tasks-list")
    end
  end

  describe "/tasks/my_teams"  do
    it "GET index should display a table with the events" do
      team1 = FactoryGirl.create(:team)
      team2 = FactoryGirl.create(:team)
      @company_user.update_attributes({:team_ids => [team1.id, team2.id]}, without_protection: true)


      user_task = FactoryGirl.create(:task, title: 'User task', company_user: @company_user , active: true, event: FactoryGirl.create(:event)),
      company_user1 = FactoryGirl.create(:company_user, team_ids:[team1.id])
      company_user2 = FactoryGirl.create(:company_user, team_ids:[team2.id])

      team_tasks = [
        FactoryGirl.create(:task, title: 'Team task 1', company_user: company_user1 , active: true, event: FactoryGirl.create(:event)),
        FactoryGirl.create(:task, title: 'Team task 2', company_user: company_user2 , active: true, event: FactoryGirl.create(:event))
      ]
      Sunspot.commit
      visit my_teams_tasks_path

      within("table#tasks-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Team task 1')
          find('td:nth-child(4)').should have_content(company_user2.full_name)
          find('td:nth-child(6)').should have_content('Edit')
          find('td:nth-child(6)').should have_content('Deactivate')
          find('td:nth-child(6)').should have_content('Comment')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('Team task 2')
          find('td:nth-child(4)').should have_content(company_user1.full_name)
          find('td:nth-child(6)').should have_content('Edit')
          find('td:nth-child(6)').should have_content('Deactivate')
          find('td:nth-child(6)').should have_content('Comment')
        end

        page.should_not have_content('User task')
      end

      assert_table_sorting ("table#tasks-list")
    end
  end
end