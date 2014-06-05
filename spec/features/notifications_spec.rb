require 'spec_helper'

feature "Notifications", search: true, js: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:team) { FactoryGirl.create(:team, name: 'Team 1') }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can see notifications' do

    it "should receive notifications for new events" do
      without_current_user do
        FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'You have a new event'

      without_current_user{ FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'You have 2 new events'

      click_notification 'You have 2 new events'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)

      visit current_url

      # reload page and make sure that only the two events are still there
      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end

    it "should receive notifications for new team events" do
      without_current_user do
        team.users << company_user
        FactoryGirl.create(:event, company: company, teams: [team], campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place) # Event not associated to the team
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'Your team Team 1 has a new event'

      without_current_user{ FactoryGirl.create(:event, company: company, teams: [team], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'Your team Team 1 has 2 new events'

      click_notification 'Your team Team 1 has 2 new events'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)

      visit current_url

      # reload page and make sure that only the two events are still there
      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end

    it "should receive notifications for new tasks assigned to him" do
      event = FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place)
      task = FactoryGirl.create(:task, event: event, company_user: company_user, due_at: nil)

      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'You have a new task'

      click_notification 'You have a new task'

      expect(current_path).to eql mine_tasks_path
      expect(page).to have_selector('#tasks-list li', count: 1)

      expect(page).to_not have_notification 'You have a new task'

      # Create two new tasks and make sure the notification is correct and then click
      # on it. The app should only list those two new tasks without showing the old one
      FactoryGirl.create(:task, event: event, company_user: company_user, due_at: nil)
      FactoryGirl.create(:task, event: event, company_user: company_user, due_at: nil)

      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'You have 2 new tasks'

      click_notification 'You have 2 new tasks'

      expect(current_path).to eql mine_tasks_path
      expect(page).to have_selector('#tasks-list li', count: 2)

      # Make sure the notification does not longer appear after the user see the list
      expect(page).to_not have_notification 'You have 2 new tasks'

      visit current_url

      # reload page and make sure that only the two tasks are still there
      expect(current_path).to eql mine_tasks_path
      expect(page).to have_selector('#tasks-list li', count: 2)
    end

    it "should receive notifications for new campaigns" do
      campaign2 = FactoryGirl.create(:campaign, company: company)
      without_current_user do # so the permissions are not validated during the event creation
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, campaign: campaign2, place: place)
      end
      Sunspot.commit

      company_user.campaigns << campaign

      visit root_path
      expect(page).to have_notification 'You have a new campaign'

      company_user.campaigns << campaign2
      Sunspot.commit

      visit current_url
      expect(page).to have_notification 'You have 2 new campaigns'

      click_notification 'You have 2 new campaigns'

      expect(current_path).to eql campaigns_path
      expect(page).to have_selector('#campaigns-list li', count: 2)

      expect(page).to_not have_notification 'You have 2 new campaigns'

      visit current_url

      # reload page and make sure that only the two events are still there
      expect(current_path).to eql campaigns_path
      expect(page).to have_selector('#campaigns-list li', count: 2)
    end
  end

  feature "Admin user" do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can see notifications"
  end

  feature "Non Admin User" do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_behaves_like "a user that can see notifications" do
      before { company_user.campaigns << [campaign] }
      before { company_user.places << place }
      let(:permissions) { [
        [:index, 'Event'], [:view_list, 'Event'],
        [:index_my, 'Task'], [:index_team, 'Task'], [:read, 'Campaign']
      ] }
    end
  end

  def click_notification(text)
    if page.all('header li#notifications.open').count == 0
      page.find('header li#notifications a.dropdown-toggle').click
    end

    page.find("#notifications .notifications-container li a", text: text).click
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create({action: p[0], subject_class: p[1]}, without_protection: true)
    end
  end
end