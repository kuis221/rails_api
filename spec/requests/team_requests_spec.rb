require 'spec_helper'

describe "Teams", :js => true do
  before do
    @user = login
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  describe "/teams" do
    it "GET index should display a table with the teams" do
      teams = [
        FactoryGirl.create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true),
        FactoryGirl.create(:team, name: 'San Francisco Team', description: 'the guys from SF', active: false)
      ]
      # Create a few users for each team
      teams[0].users << FactoryGirl.create_list(:user, 3, company_id: @company.id)
      teams[1].users << FactoryGirl.create_list(:user, 2, company_id: @company.id)
      visit teams_path

      within("table#teams-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Costa Rica Team')
          find('td:nth-child(2)').should have_content('3')
          find('td:nth-child(3)').should have_content('el grupo de ticos')
          find('td:nth-child(4)').should have_content('Active')
          find('td:nth-child(5)').should have_content('Edit')
          find('td:nth-child(5)').should have_content('Deactivate')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('San Francisco Team')
          find('td:nth-child(2)').should have_content('2')
          find('td:nth-child(3)').should have_content('the guys from SF')
          find('td:nth-child(4)').should have_content('Inactive')
          find('td:nth-child(5)').should have_content('Edit')
          find('td:nth-child(5)').should have_content('Activate')
        end
      end

      assert_table_sorting ("table#teams-list")

    end

    it 'allows the user to create a new team' do
      visit teams_path

      click_link('New Team')

      within("form#new_team") do
        fill_in 'Name', with: 'new team name'
        fill_in 'Description', with: 'new team description'
        click_button 'Create Team'
      end

      sleep(1)
      find('h2', text: 'new team name') # Wait for the page to load
      page.should have_selector('h2', text: 'new team name')
      page.should have_selector('div.team-description', text: 'new team description')
    end
  end

  describe "/teams/:team_id", :js => true do
    it "GET show should display the team details page" do
      team = FactoryGirl.create(:team, name: 'Some Team Name', description: 'a team description')
      visit team_path(team)
      page.should have_selector('h2', text: 'Some Team Name')
      page.should have_selector('div.team-description', text: 'a team description')
    end

    it 'diplays a table of users within the team details page' do
      team = FactoryGirl.create(:team)
      users = [
        FactoryGirl.create(:user, first_name: 'First1', last_name: 'Last1', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @company, name: 'Brand Manager').id, city: 'Miami', state:'FL', country:'US', email: 'user1@example.com'),
        FactoryGirl.create(:user, first_name: 'First2', last_name: 'Last2', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @company, name: 'Staff').id, city: 'Brooklyn', state:'NY', country:'US', email: 'user2@example.com')
      ]
      team.users << users
      visit team_path(team)
      within('table#team-members') do
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Last1')
          find('td:nth-child(2)').should have_content('First1')
          find('td:nth-child(3)').should have_content('Brand Manager')
          find('td:nth-child(4)').should have_content('Miami')
          find('td:nth-child(5)').should have_content('Florida')
          find('td:nth-child(6)').should have_content('user1@example.com')
          find('td:nth-child(7)').should have_content('Active')
          find('td:nth-child(8)').should have_content('Remove')
        end
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('Last2')
          find('td:nth-child(2)').should have_content('First2')
          find('td:nth-child(3)').should have_content('Staff')
          find('td:nth-child(4)').should have_content('Brooklyn')
          find('td:nth-child(5)').should have_content('New York')
          find('td:nth-child(6)').should have_content('user2@example.com')
          find('td:nth-child(7)').should have_content('Active')
          find('td:nth-child(8)').should have_content('Remove')
        end
      end

      assert_table_sorting ("table#team-members")
    end

    it 'allows the user to activate/deactivate a team' do
      team = FactoryGirl.create(:team, active: true)
      visit team_path(team)
      within('.active-deactive-toggle') do
        page.should have_selector('a.btn-success.active', text: 'Active')
        page.should have_selector('a', text: 'Inactive')
        page.should_not have_selector('a.btn-danger', text: 'Inactive')

        click_link('Inactive')
        page.should have_selector('a.btn-danger.active', text: 'Inactive')
        page.should have_selector('a', text: 'Active')
        page.should_not have_selector('a.btn-success', text: 'Active')
      end
    end

    it 'allows the user to edit the team' do
      team = FactoryGirl.create(:team)
      visit team_path(team)

      click_link('Edit')

      within("form#edit_team_#{team.id}") do
        fill_in 'Name', with: 'edited team name'
        fill_in 'Description', with: 'edited team description'
        click_button 'Update Team'
      end

      sleep(1)
      find('h2', text: 'edited team name') # Wait for the page to reload
      page.should have_selector('h2', text: 'edited team name')
      page.should have_selector('div.team-description', text: 'edited team description')
    end


    it 'allows the user to add the users to the team' do
      team = FactoryGirl.create(:team)
      user = FactoryGirl.create(:user, first_name: 'Fulanito', last_name: 'DeTal', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @user.current_company, name: 'Brand Manager').id, city: 'Miami', state:'FL', country:'US', email: 'user1@example.com')

      visit team_path(team)

      within('table#team-members') do
        page.should_not have_content('Fulanito')
      end

      click_link('Add Team Member')


      within visible_modal do
        object_row(user).click_js_link('Add')
      end

      modal_footer.click_link 'Close'

      within('table#team-members') do
        page.should have_content('Fulanito')
      end
    end
  end

end