require 'rails_helper'

describe CompanyUsersController, type: :controller, search: true do
  let(:company) { create(:company) }
  let(:user) { company_user.user }

  before { sign_in_as_user company_user }

  describe 'As Super User' do
    let(:company_user) { create(:company_user, company: company) }

    describe "GET 'notifications'" do
      let(:timestamp) { Time.now.to_datetime.strftime('%Q').to_i }
      it 'should return a notification if a user is added to a campaign' do
        Timecop.freeze do
          company_user.update_attributes(notifications_settings: ['new_campaign_app'])
          campaign = create(:campaign, company: company)
          company_user.campaigns << campaign
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'You have a new campaign',
            'level' => 'grey',
            'url' => campaigns_path(new_at: timestamp),
            'unread' => true,
            'icon' => 'icon-campaign',
            'type' => 'new_campaign')
        end
      end

      it "should return a notification if a user is added to a event's team" do
        Timecop.freeze do
          company_user.update_attributes(notifications_settings: ['new_event_team_app'])
          event = create(:event, company: company)
          event.users << company_user
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'You have a new event',
            'level' => 'grey',
            'url' => events_path(new_at: timestamp, end_date: '', start_date: ''),
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'new_event')
        end
      end

      it "should return a notification if a user team is added to a event's team" do
        Timecop.freeze do
          event1 = create(:event, company: company)
          company_user.update_attributes(notifications_settings: ['new_event_team_app'])
          company_user.notifications.delete_all
          team1 = create(:team, name: 'Team A', company: company)
          team1.users << company_user
          event1.teams << team1
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'Your team Team A has a new event',
            'level' => 'grey',
            'url' => events_path(notification: 'new_team_event',
                                 team: [team1.id], new_at: timestamp,
                                 end_date: '', start_date: ''),
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'new_team_event')

          # New user team added to a new event, different message is obtained
          event2 = create(:event, company: company)
          team2 = create(:team, name: 'Team B', company: company)
          team2.users << company_user
          event2.teams << team2
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'You teams Team A, Team B have 2 new events',
            'level' => 'grey',
            'url' => events_path(notification: 'new_team_event', team: [team1.id, team2.id],
                                 new_at: timestamp, end_date: '', start_date: ''),
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'new_team_event')
        end
      end

      it 'should return a notification if the user have a late event recap' do
        company_user.update_attributes(notifications_settings: ['event_recap_late_app'])
        event = create(:late_event, company: company)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one late event recap',
          'level' => 'red',
          'url' => '/events?end_date=&event_status%5B%5D=Late&start_date=&'\
                   "status%5B%5D=Active&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_late')
      end

      it "should NOT return a notification if the user is not part of the event's team" do
        company_user.update_attributes(notifications_settings: ['new_event_team_app'])
        without_current_user do
          create(:late_event, company: company)
        end
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to eq([])
      end

      it 'should return a notification if the user have a submitted event recap that is waiting for approval' do
        company_user.update_attributes(notifications_settings: ['event_recap_pending_approval_app'])
        event = create(:submitted_event, company: company)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one event recap that is pending approval',
          'level' => 'blue',
          'url' => '/events?end_date=&event_status%5B%5D=Submitted&start_date=&'\
                   "status%5B%5D=Active&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_pending')
      end

      it 'should return a notification if the user have a due event recap' do
        company_user.update_attributes(notifications_settings: ['event_recap_due_app'])
        event = create(:due_event, company: company)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one event recap that is due',
          'level' => 'grey',
          'url' => '/events?end_date=&event_status%5B%5D=Due&start_date=&'\
                   "status%5B%5D=Active&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_due')
      end

      it 'should return a notification if the user has is assigned to a task that is late' do
        company_user.update_attributes(notifications_settings: ['late_task_app'])
        event = create(:event, company: company)
        create(:late_task, event: event, company_user_id: company_user.id)

        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'You have one late task',
          'level' => 'red',
          'url' => '/tasks/mine?end_date=&start_date=&status%5B%5D=Active&'\
                   "task_status%5B%5D=Late&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-tasks',
          'type' => 'user_tasks_late')
      end

      it "should return a notification if the user is part of the event's team that have a late task" do
        company_user.update_attributes(notifications_settings: ['late_team_task_app'])
        event = create(:event, company: company)
        event.users << company_user
        create(:late_task, event: event, company_user_id: nil)

        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'Your team has one late task',
          'level' => 'red',
          'url' => "/tasks/my_teams?end_date=&not_assigned_to%5B%5D=#{company_user.id}"\
                   '&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&'\
                   "team_members%5B%5D=#{company_user.id}",
          'unread' => true, 'icon' => 'icon-tasks',
          'type' => 'team_tasks_late')
      end

      it 'should return a notification if there is a new task for the user' do
        company_user.update_attributes(notifications_settings: ['new_task_assignment_app'])
        Timecop.freeze do
          without_current_user do
            create(:task,
                   title: 'The task title',
                   event: create(:event, company: company), company_user: company_user)
          end

          get 'notifications', id: company_user.to_param, format: :json

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'You have a new task',
            'level' => 'grey',
            'url' => "/tasks/mine?new_at=#{timestamp}",
            'unread' => true,
            'icon' => 'icon-tasks',
            'type' => 'new_task')
        end
      end

      it "should return a notification if there is a new comment for a user's task" do
        company_user.update_attributes(notifications_settings: ['new_comment_app'])
        task = create(:task, title: 'The task title',
                             event: create(:event, company: company), company_user: company_user)
        comment = create(:comment, commentable: task)
        comment.update_column(:created_by_id, create(:company_user, company: company).user.id)

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'Your task <span>The task title</span> has a new comment',
          'level' => 'grey',
          'url' => "/tasks/mine?task%5B%5D=#{task.id}#comments-#{task.id}",
          'unread' => true,
          'icon' => 'icon-comments',
          'type' => 'user_task_comments',
          'task_id' => task.id)
      end

      it "should return a notification if there is a new comment for a user's team task" do
        company_user.update_attributes(notifications_settings: ['new_team_comment_app'])
        task = create(:task, title: 'The task title', event: create(:event, company: company))
        task.event.users << company_user
        comment = create(:comment, commentable: task)
        comment.update_column(:created_by_id, company_user.user.id + 1)

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => "Your team's task <span>The task title</span> has a new comment",
          'level' => 'grey',
          'url' => "/tasks/my_teams?task%5B%5D=#{task.id}#comments-#{task.id}",
          'unread' => true,
          'icon' => 'icon-comments',
          'type' => 'team_task_comments',
          'task_id' => task.id)
      end
    end

    describe 'when notification policy is set to EVENT_ALERT_POLICY_ALL' do
      let(:campaign) { create(:campaign, company: company) }
      before { company.update_attribute(:event_alerts_policy, Notification::EVENT_ALERT_POLICY_ALL) }

      it 'should notify all users about late events that they have access to' do
        company_user.update_attributes(notifications_settings: ['event_recap_late_app'])
        create(:late_event, campaign: campaign)
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one late event recap',
          'level' => 'red',
          'url' => '/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active',
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_late')
      end

      it 'should return a notification if the user have a submitted event recap that is waiting for approval' do
        company_user.update_attributes(notifications_settings: ['event_recap_pending_approval_app'])
        create(:submitted_event, campaign: campaign)
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one event recap that is pending approval',
          'level' => 'blue',
          'url' => '/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active',
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_pending')
      end

      it 'should return a notification if the user have a due event recap' do
        company_user.update_attributes(notifications_settings: ['event_recap_due_app'])
        create(:due_event, campaign: campaign)
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one event recap that is due',
          'level' => 'grey',
          'url' => '/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active',
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_due')
      end
    end
  end

  describe 'As NOT Super User' do
    let(:company_user) do
      create(:company_user,
             company: company,
             permissions: [[:view_list, 'Event']],
             role: create(:non_admin_role, company: company))
    end
    let(:campaign) { create(:campaign, company: company) }
    let(:place) { create(:place) }

    describe "GET 'notifications'" do
      let(:timestamp) { Time.now.to_datetime.strftime('%Q').to_i }
      it "should return a notification if a user is added to a event's team" do
        Timecop.freeze do
          company_user.update_attributes(notifications_settings: ['new_event_team_app'])
          company_user.places << place
          campaign.places << place
          company_user.campaigns << campaign
          event = without_current_user { create(:event, company: company, place: place) }
          event.users << company_user
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'You have a new event',
            'level' => 'grey',
            'url' => events_path(new_at: timestamp, end_date: '', start_date: ''),
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'new_event')
        end
      end

      it 'should return a notification if the user have a late event recap' do
        company_user.update_attributes(notifications_settings: ['event_recap_late_app'])
        company_user.places << place
        campaign.places << place
        campaign.users << company_user
        event = create(:late_event, company: company, campaign: campaign, place: place)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one late event recap',
          'level' => 'red',
          'url' => '/events?end_date=&event_status%5B%5D=Late&start_date='\
                   "&status%5B%5D=Active&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_late')
      end

      it 'should return a notification if the user have a submitted event recap that is waiting for approval' do
        company_user.update_attributes(notifications_settings: ['event_recap_pending_approval_app'])
        company_user.places << place
        campaign.places << place
        campaign.users << company_user
        event = create(:submitted_event, company: company, campaign: campaign, place: place)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one event recap that is pending approval',
          'level' => 'blue',
          'url' => '/events?end_date=&event_status%5B%5D=Submitted&start_date=&'\
                   "status%5B%5D=Active&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_pending')
      end

      it 'should return a notification if the user have a due event recap' do
        company_user.update_attributes(notifications_settings: ['event_recap_due_app'])
        company_user.places << place
        campaign.places << place
        campaign.users << company_user
        event = create(:due_event, company: company, campaign: campaign, place: place)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include(
          'message' => 'There is one event recap that is due',
          'level' => 'grey',
          'url' => '/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active'\
                   "&user%5B%5D=#{company_user.id}",
          'unread' => true,
          'icon' => 'icon-events',
          'type' => 'event_recaps_due')
      end

      describe 'when notification policy is set to EVENT_ALERT_POLICY_ALL' do
        let(:campaign) { create(:campaign, company: company) }
        let(:place) { create(:place, city: 'Los Angeles', state: 'CA', country: 'US') }
        let(:city) { create(:city, name: 'Los Angeles', state: 'CA', country: 'US') }
        before { company_user.places << city }
        before { company.update_attribute(:settings, event_alerts_policy: Notification::EVENT_ALERT_POLICY_ALL) }
        before { campaign.places << city }
        before { campaign.users << company_user }

        it 'should notify all users about late events that they have access to' do
          company_user.update_attributes(notifications_settings: ['event_recap_late_app'])
          without_current_user { create(:late_event, campaign: campaign, place: place) }

          # Another events the user should not have access to
          without_current_user { create(:late_event, campaign: campaign) }
          without_current_user { create(:late_event, place: place) }
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'There is one late event recap',
            'level' => 'red',
            'url' => '/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active',
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'event_recaps_late')
        end

        it 'should return a notification if the user have a submitted event recap that is waiting for approval' do
          company_user.update_attributes(notifications_settings: ['event_recap_pending_approval_app'])
          without_current_user { create(:submitted_event, campaign: campaign, place: place) }

          # Another events the user should not have access to
          without_current_user { create(:submitted_event, campaign: campaign) }
          without_current_user { create(:submitted_event, place: place) }
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'There is one event recap that is pending approval',
            'level' => 'blue',
            'url' => '/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active',
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'event_recaps_pending')
        end

        it 'should return a notification if the user have a due event recap' do
          company_user.update_attributes(notifications_settings: ['event_recap_due_app'])
          without_current_user { create(:due_event, campaign: campaign, place: place) }

          # Another events the user should not have access to
          without_current_user { create(:due_event, campaign: campaign) }
          without_current_user { create(:due_event, place: place) }

          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include(
            'message' => 'There is one event recap that is due',
            'level' => 'grey',
            'url' => '/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active',
            'unread' => true,
            'icon' => 'icon-events',
            'type' => 'event_recaps_due')
        end
      end
    end
  end
end
