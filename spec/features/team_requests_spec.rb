require 'rails_helper'

feature 'Teams', js: true do
  let(:company) { create(:company) }
  let(:user) { create(:user, company_id: company.id, role_id: create(:role, company: company).id) }

  before { sign_in user }
  after { Warden.test_reset! }

  feature '/teams', search: true  do
    scenario 'GET index should display a list with the teams' do
      teams = [
        create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true, company_id: company.id),
        create(:team, name: 'San Francisco Team', description: 'the guys from SF', active: true, company_id: company.id)
      ]
      # Create a few users for each team
      teams[0].users << create_list(:company_user, 3, company_id: company.id)
      teams[1].users << create_list(:company_user, 2, company_id: company.id)
      Sunspot.commit

      visit teams_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content('Costa Rica Team')
        expect(page).to have_text('3 Members')
        expect(page).to have_content('el grupo de ticos')
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('San Francisco Team')
        expect(page).to have_text('2 Members')
        expect(page).to have_content('the guys from SF')
      end
    end

    scenario 'allows the user to activate/deactivate teams' do
      create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true, company: company)
      Sunspot.commit

      visit teams_path

      within resource_item do
        expect(page).to have_content('Costa Rica Team')
        click_js_link 'Deactivate'
      end

      confirm_prompt 'Are you sure you want to deactivate this team?'

      expect(page).to have_no_content('Costa Rica Team')

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within resource_item do
        expect(page).to have_content('Costa Rica Team')
        click_js_link 'Activate'
      end
      expect(page).to have_no_content('Costa Rica Team')
    end

    scenario 'allows the user to create a new team' do
      visit teams_path

      click_js_button 'New Team'

      within visible_modal do
        fill_in 'Name', with: 'new team name'
        fill_in 'Description', with: 'new team description'
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new team name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new team name')
      expect(page).to have_selector('div.description-data', text: 'new team description')
    end
  end

  feature '/teams/:team_id', js: true do
    scenario 'GET show should display the team details page' do
      team = create(:team, name: 'Some Team Name', description: 'a team description', company_id: company.id)
      visit team_path(team)
      expect(page).to have_selector('h2', text: 'Some Team Name')
      expect(page).to have_selector('div.description-data', text: 'a team description')
    end

    scenario 'diplays a list of users within the team details page' do
      team = create(:team, company_id: company.id)
      users = [
        create(:user, first_name: 'First1', last_name: 'Last1', company_id: company.id,
               role_id: create(:role, company: company, name: 'Brand Manager').id,
               city: 'Miami', state: 'FL', country: 'US', email: 'user1@example.com'),
        create(:user, first_name: 'First2', last_name: 'Last2', company_id: company.id,
               role_id: create(:role, company: company, name: 'Staff').id,
               city: 'Brooklyn', state: 'NY', country: 'US', email: 'user2@example.com')
      ]
      users.each { |u| u.company_users.each { |cu |team.users << cu.reload } }
      Sunspot.commit
      visit team_path(team)
      within('#team-members-list') do
        within('div.team-member:nth-child(1)') do
          expect(page).to have_content('First1 Last1')
          expect(page).to have_content('Brand Manager')
          expect(page).to have_selector('a.remove-member-btn', visible: false)
        end
        within('div.team-member:nth-child(2)') do
          expect(page).to have_content('First2 Last2')
          expect(page).to have_content('Staff')
          expect(page).to have_selector('a.remove-member-btn', visible: false)
        end
      end
    end

    scenario 'allows the user to activate/deactivate a team' do
      team = create(:team, active: true, company_id: company.id)
      visit team_path(team)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this team?'

      within('.links-data') do
        click_js_link 'Activate'
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end

    scenario 'allows the user to edit the team' do
      team = create(:team, company_id: company.id)
      Sunspot.commit
      visit team_path(team)

      within('.links-data') { click_js_button 'Edit Team' }

      within visible_modal do
        fill_in 'Name', with: 'edited team name'
        fill_in 'Description', with: 'edited team description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'edited team name')
      expect(page).to have_selector('div.description-data', text: 'edited team description')
    end

    scenario 'allows the user to add the users to the team' do
      team = create(:team, company_id: company.id)
      user = create(:user, first_name: 'Fulanito', last_name: 'DeTal',
        company_id: company.id,
        role_id: create(:role, company: company, name: 'Brand Manager').id,
        city: 'Miami', state: 'FL', country: 'US', email: 'user1@example.com')
      company_user = user.company_users.first
      Sunspot.commit
      visit team_path(team)

      expect(page).to_not have_content('Fulanito')

      click_js_link('Add Team Member')

      within visible_modal do
        find("#staff-member-user-#{company_user.id}").hover
        click_js_link('Add')
      end

      close_modal

      within('#team-members-list')  do
        expect(page).to have_content('Fulanito')
      end
    end
  end

end
