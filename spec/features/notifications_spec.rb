require 'rails_helper'

feature "Notifications", search: true, js: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:team) { FactoryGirl.create(:team, name: 'Team 1', company: company ) }
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
      company_user.update_attributes({notifications_settings: ['new_event_team_app']})
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
      company_user.update_attributes({notifications_settings: ['new_event_team_app']})
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

    it "should receive notifications when user is added to a event's team" do
      company_user.update_attributes(notifications_settings: ['new_event_team_app'])
      event = without_current_user { FactoryGirl.create(:event, company: company, campaign: campaign, place: place) }
      Sunspot.commit

      visit event_path(event)

      expect(page).not_to have_notification 'You have a new event'

      click_js_link 'Add Team Member'
      within visible_modal do
        fill_in 'staff-search-item', with: user.name
        click_js_link("Add")
      end
      close_modal

      visit events_path
      expect(page).to have_selector('#events-list li', count: 1)

      # Visit event and make sure the notification is removed
      visit event_path(event)

      expect(page).not_to have_notification 'You have a new event'
    end


    it "should receive notifications when user's team is added to a event's team" do
      company_user.update_attributes(notifications_settings: ['new_event_team_app'])
      event = without_current_user { FactoryGirl.create(:event, company: company, campaign: campaign, place: place) }
      Sunspot.commit

      team = FactoryGirl.create(:team, name: 'SuperAmigos', company: company)
      team.users << company_user

      visit event_path(event)

      expect(page).not_to have_notification 'You have a new event'

      click_js_link 'Add Team Member'
      within visible_modal do
        fill_in 'staff-search-item', with: 'SuperAmigos'
        click_js_link("Add")
        expect(page).not_to have_content('SuperAmigos')
      end
      close_modal
      expect(event.teams).to include(team)

      visit events_path
      expect(page).to have_selector('#events-list li', count: 1)

      # Visit event and make sure the notification is removed
      visit event_path(event)

      expect(page).not_to have_notification 'You have a new event'
    end

    it "should remove notifications for new events visited" do
      company_user.update_attributes({notifications_settings: ['new_event_team_app']})
      without_current_user do # so the permissions are not validated during the event creation
        FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'You have 2 new events'

      #New events counter should be decreased by 1
      visit event_path(company_user.events.first)
      expect(page).to have_notification 'You have a new event'
    end

    it "should receive notifications for due events recaps" do
      company_user.update_attributes({notifications_settings: ['event_recap_due_app']})
      without_current_user do
        FactoryGirl.create(:due_event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:due_event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'There is one event recap that is due'

      without_current_user{ FactoryGirl.create(:due_event, company: company, users: [company_user], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'There are 2 event recaps that are due'

      click_notification 'There are 2 event recaps that are due'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end

    it "should receive notifications for late events recaps" do
      company_user.update_attributes({notifications_settings: ['event_recap_late_app']})
      without_current_user do
        FactoryGirl.create(:late_event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:late_event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'There is one late event recap'

      without_current_user{ FactoryGirl.create(:late_event, company: company, users: [company_user], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'There are 2 late event recaps'

      click_notification 'There are 2 late event recaps'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end

    it "should receive notifications for pending approval events recaps" do
      company_user.update_attributes({notifications_settings: ['event_recap_pending_approval_app']})
      without_current_user do
        FactoryGirl.create(:submitted_event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'There is one event recap that is pending approval'

      without_current_user{ FactoryGirl.create(:submitted_event, company: company, users: [company_user], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'There are 2 event recaps that are pending approval'

      click_notification 'There are 2 event recaps that are pending approval'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end

    it "should receive notifications for rejected events recaps" do
      company_user.update_attributes({notifications_settings: ['event_recap_rejected_app']})
      without_current_user do
        FactoryGirl.create(:rejected_event, company: company, users: [company_user], campaign: campaign, place: place)
        FactoryGirl.create(:rejected_event, company: company, campaign: campaign, place: place) # Event not associated to the user
      end
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'There is one event recap that has been rejected'

      without_current_user{ FactoryGirl.create(:rejected_event, company: company, users: [company_user], campaign: campaign, place: place) }
      Sunspot.commit
      visit root_path
      expect(page).to have_notification 'There are 2 event recaps that have been rejected'

      click_notification 'There are 2 event recaps that have been rejected'

      expect(current_path).to eql events_path
      expect(page).to have_selector('#events-list li', count: 2)
    end

    it "should receive notifications for new tasks assigned to him" do
      company_user.update_attributes({notifications_settings: ['new_task_assignment_app']})
      event = FactoryGirl.create(:event, company: company, users: [company_user], campaign: campaign, place: place)
      task = FactoryGirl.create(:task, title: 'My Task #1', event: event, company_user: company_user, due_at: nil)

      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'You have a new task'

      click_notification 'You have a new task'

      expect(current_path).to eql mine_tasks_path
      expect(page).to have_content('My Task #1')

      expect(page).to_not have_notification 'You have a new task'

      # Create two new tasks and make sure the notification is correct and then click
      # on it. The app should only list those two new tasks without showing the old one
      FactoryGirl.create(:task, title: 'My Task #2', event: event, company_user: company_user, due_at: nil)
      FactoryGirl.create(:task, title: 'My Task #3', event: event, company_user: company_user, due_at: nil)
      Sunspot.commit

      visit root_path
      expect(page).to have_notification 'You have 2 new tasks'

      click_notification 'You have 2 new tasks'

      expect(current_path).to eql mine_tasks_path
      expect(page).to have_content('My Task #2')
      expect(page).to have_content('My Task #3')

      # Make sure the notification does not longer appear after the user see the list
      expect(page).to_not have_notification 'You have 2 new tasks'

      visit current_url

      # reload page and make sure that only the two tasks are still there
      expect(current_path).to eql mine_tasks_path
      expect(page).to have_content('My Task #2')
      expect(page).to have_content('My Task #3')
    end

    it "should receive notifications for new campaigns" do
      company_user.update_attributes({notifications_settings: ['new_campaign_app']})
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

    it "should remove notifications for new campaigns visited" do
      company_user.update_attributes({notifications_settings: ['new_campaign_app']})
      campaign2 = FactoryGirl.create(:campaign, company: company)
      without_current_user do # so the permissions are not validated during the event creation
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
        FactoryGirl.create(:event, company: company, campaign: campaign2, place: place)
      end
      Sunspot.commit

      company_user.campaigns << campaign
      company_user.campaigns << campaign2

      visit root_path
      expect(page).to have_notification 'You have 2 new campaigns'

      #New campaigns counter should be decreased by 1
      visit campaign_path(company_user.campaigns.first)
      expect(page).to have_notification 'You have a new campaign'
    end

    feature "notification alert policy set to ALL" do
      before { company.update_attribute(:event_alerts_policy, Notification::EVENT_ALERT_POLICY_ALL) }

      it "should receive notifications for late events recaps" do
        company_user.update_attributes({notifications_settings: ['event_recap_late_app']})
        without_current_user do
          FactoryGirl.create(:late_event, company: company, campaign: campaign, place: place)
        end
        Sunspot.commit

        visit root_path
        expect(page).to have_notification 'There is one late event recap'

        without_current_user{ FactoryGirl.create(:late_event, company: company, campaign: campaign, place: place) }
        Sunspot.commit
        visit root_path
        expect(page).to have_notification 'There are 2 late event recaps'

        click_notification 'There are 2 late event recaps'

        expect(current_path).to eql events_path
        expect(page).to have_selector('#events-list li', count: 2)
      end

      it "should receive notifications for new tasks not assigned to him as tasks for the team" do
        company_user.update_attributes({notifications_settings: ['late_team_task_app']})
        event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
        task = FactoryGirl.create(:task, title: 'My Team Task #1', event: event, company_user: nil, due_at: 2.days.ago.to_s(:slashes))

        Sunspot.commit

        visit root_path
        expect(page).to have_notification 'Your team has one late task'

        click_notification 'Your team has one late task'

        expect(current_path).to eql my_teams_tasks_path
        expect(page).to have_content('My Team Task #1')

        # Create two new tasks and make sure the notification is correct and then click
        # on it. The app should only list those two late tasks without showing the old one
        FactoryGirl.create(:task, title: 'My Team Task #2', event: event, due_at: 2.days.ago.to_s(:slashes))
        FactoryGirl.create(:task, title: 'My Team Task #3', event: event, due_at: 2.days.ago.to_s(:slashes))
        Sunspot.commit

        visit root_path
        expect(page).to have_notification 'Your team has 3 late tasks'

        click_notification 'Your team has 3 late tasks'

        expect(current_path).to eql my_teams_tasks_path
        expect(page).to have_content('My Team Task #1')
        expect(page).to have_content('My Team Task #2')
        expect(page).to have_content('My Team Task #3')

        # Make sure the notification is still there
        expect(page).to have_notification 'Your team has 3 late tasks'
      end
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
        [:index, 'Event'], [:view_list, 'Event'], [:show, 'Event'], [:add_members, 'Event'], [:view_members, 'Event'],
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
      company_user.role.permissions.create(action: p[0], subject_class: p[1])
    end
  end
end