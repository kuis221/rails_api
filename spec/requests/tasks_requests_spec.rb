require 'spec_helper'

describe "Tasks", js: true, search: true do

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

  describe "/tasks/mine"  do
    it "GET index should display a table with the events" do
      tasks = [
        FactoryGirl.create(:task, title: 'Pick up kidz at school', company_user: @company_user, due_at: '2013-09-01', active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Cacique FY14', company: @company))),
        FactoryGirl.create(:task, title: 'Bring beers to the party', company_user: @company_user, due_at: '2013-09-02' , active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Centenario FY14', company: @company)))
      ]
      Sunspot.commit
      visit mine_tasks_path

      within("ul#tasks-list") do
        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Pick up kidz at school')
          page.should have_content('SUN Sep 1')
          page.should have_content('Cacique FY14')
        end

        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('Bring beers to the party')
          page.should have_content('MON Sep 2')
          page.should have_content('Centenario FY14')
        end

      end

    end
  end

  describe "/tasks/my_teams"  do
    it "GET index should display a table with the events" do
      team1 = FactoryGirl.create(:team, company: @company)
      team2 = FactoryGirl.create(:team, company: @company)
      @company_user.update_attributes({:team_ids => [team1.id, team2.id]}, without_protection: true)


      user_task = FactoryGirl.create(:task, title: 'User task', company_user: @company_user , active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Cacique FY14', company: @company))),
      company_user1 = FactoryGirl.create(:company_user, team_ids:[team1.id], company: @company)
      company_user2 = FactoryGirl.create(:company_user, team_ids:[team2.id], company: @company)

      team_tasks = [
        FactoryGirl.create(:task, title: 'Team task 1', due_at: '2013-09-01', company_user: company_user1 , active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Centenario FY14', company: @company))),
        FactoryGirl.create(:task, title: 'Team task 2', due_at: nil, company_user: company_user2 , active: true, event: FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, name: 'Absolut FY14', company: @company)))
      ]
      Sunspot.commit
      visit my_teams_tasks_path

      within("ul#tasks-list") do
        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Team task 2')
          #page.should have_content(company_user1.full_name)
          page.should have_content('Absolut FY14')
        end

        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('Team task 1')
          #page.should have_content(company_user2.full_name)
          page.should have_content('Centenario FY14')
          page.should have_content('SUN Sep 1')
        end

        page.should_not have_content('User task')
      end

    end
  end
end