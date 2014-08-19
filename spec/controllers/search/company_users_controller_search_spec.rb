require 'rails_helper'

describe CompanyUsersController, type: :controller, search: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:user) { company_user.user }

  before { sign_in_as_user company_user }

  describe "As Super User" do
    let(:company_user) { FactoryGirl.create(:company_user, company: company) }

    describe "GET 'autocomplete'" do
      it "should return the correct buckets in the right order" do
        Sunspot.commit
        get 'autocomplete'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        expect(buckets.map{|b| b['label']}).to eq(['Users','Teams', 'Roles', 'Campaigns', 'Places'])
      end

      it "should return the users in the User Bucket" do
        user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'Users'}.first
        expect(people_bucket['value']).to eq([{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}])
      end


      it "should return the teams in the Teams Bucket" do
        team = FactoryGirl.create(:team, name: 'Spurs', company_id: company.id)
        Sunspot.commit

        get 'autocomplete', q: 'sp'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'Teams'}.first
        expect(people_bucket['value']).to eq([{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}])
      end

      it "should return the campaigns in the Campaigns Bucket" do
        campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
        expect(campaigns_bucket['value']).to eq([{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}])
      end

      it "should return the roles in the Roles Bucket" do
        role = FactoryGirl.create(:role, name: 'Campaing Staff', company: company)
        Sunspot.commit

        get 'autocomplete', q: 'staff'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.select{|b| b['label'] == 'Roles'}.first
        expect(places_bucket['value']).to eq([{"label"=>"Campaing <i>Staff</i>", "value"=>role.id.to_s, "type"=>"role"}])
      end

      it "should return the venues in the Places Bucket" do
        expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
        venue = FactoryGirl.create(:venue, company_id: company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
        Sunspot.commit

        get 'autocomplete', q: 'mot'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
        expect(places_bucket['value']).to eq([{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}])
      end

      describe "when notification policy is set to EVENT_ALERT_POLICY_ALL" do
        let(:campaign) { FactoryGirl.create(:campaign, company: company) }
        before { company.update_attribute(:event_alerts_policy, Notification::EVENT_ALERT_POLICY_ALL) }

        it "should notify all users about late events that they have access to" do
          company_user.update_attributes({notifications_settings: ['event_recap_late_app']})
          event = FactoryGirl.create(:late_event, campaign: campaign)
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_late"})
        end

        it "should return a notification if the user have a submitted event recap that is waiting for approval" do
          company_user.update_attributes({notifications_settings: ['event_recap_pending_approval_app']})
          event = FactoryGirl.create(:submitted_event, campaign: campaign)
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_pending"})
        end

        it "should return a notification if the user have a due event recap" do
          company_user.update_attributes({notifications_settings: ['event_recap_due_app']})
          event = FactoryGirl.create(:due_event, campaign: campaign)
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_due"})
        end
      end
    end

    describe "GET 'notifications'" do
      let(:timestamp) { Time.now.to_datetime.strftime('%Q').to_i }
      it "should return a notification if a user is added to a campaign" do
        Timecop.freeze do
          company_user.update_attributes({notifications_settings: ['new_campaign_app']})
          campaign = FactoryGirl.create(:campaign, company: company)
          company_user.campaigns << campaign
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "You have a new campaign", "level" => "grey", "url" => campaigns_path(new_at: timestamp), "unread" => true, "icon" => "icon-notification-campaign", "type"=>"new_campaign"})
        end
      end

      it "should return a notification if a user is added to a event's team" do
        Timecop.freeze do
          company_user.update_attributes({notifications_settings: ['new_event_team_app']})
          event = FactoryGirl.create(:event, company: company)
          event.users << company_user
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "You have a new event", "level" => "grey", "url" => events_path(new_at: timestamp, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_event"})
        end
      end

      it "should return a notification if a user team is added to a event's team" do
        Timecop.freeze do
          event1 = FactoryGirl.create(:event, company: company)
          company_user.update_attributes({notifications_settings: ['new_event_team_app']})
          company_user.notifications.delete_all
          team1 = FactoryGirl.create(:team, name: 'Team A', company: company)
          team1.users << company_user
          event1.teams << team1
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "Your team Team A has a new event", "level" => "grey", "url" => events_path(notification: 'new_team_event', team: [team1.id], new_at: timestamp, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_team_event"})

          #New user team added to a new event, different message is obtained
          event2 = FactoryGirl.create(:event, company: company)
          team2 = FactoryGirl.create(:team, name: 'Team B', company: company)
          team2.users << company_user
          event2.teams << team2
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "You teams Team A, Team B have 2 new events", "level" => "grey", "url" => events_path(notification: 'new_team_event', team: [team1.id, team2.id], new_at: timestamp, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_team_event"})
        end
      end

      it "should return a notification if the user have a late event recap" do
        company_user.update_attributes({notifications_settings: ['event_recap_late_app']})
        event = FactoryGirl.create(:late_event, company: company)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_late"})
      end

      it "should NOT return a notification if the user is not part of the event's team" do
        company_user.update_attributes({notifications_settings: ['new_event_team_app']})
        without_current_user do
          event = FactoryGirl.create(:late_event, company: company)
        end
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to eq([])
      end

      it "should return a notification if the user have a submitted event recap that is waiting for approval" do
        company_user.update_attributes({notifications_settings: ['event_recap_pending_approval_app']})
        event = FactoryGirl.create(:submitted_event, company: company)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_pending"})
      end

      it "should return a notification if the user have a due event recap" do
        company_user.update_attributes({notifications_settings: ['event_recap_due_app']})
        event = FactoryGirl.create(:due_event, company: company)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_due"})
      end

      it "should return a notification if the user has is assigned to a task that is late" do
        company_user.update_attributes({notifications_settings: ['late_task_app']})
        event = FactoryGirl.create(:event, company: company)
        task = FactoryGirl.create(:late_task, event: event, company_user_id: company_user.id)

        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"You have one late task", "level"=>"red", "url"=>"/tasks/mine?end_date=&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"user_tasks_late"})
      end

      it "should return a notification if the user is part of the event's team that have a late task" do
        company_user.update_attributes({notifications_settings: ['late_team_task_app']})
        event = FactoryGirl.create(:event, company: company)
        event.users << company_user
        task = FactoryGirl.create(:late_task, event: event, company_user_id: nil)

        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"Your team has one late task", "level"=>"red", "url"=>"/tasks/my_teams?end_date=&not_assigned_to%5B%5D=#{company_user.id}&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&team_members%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"team_tasks_late"})
      end

      # it "should return a notification if the user is part of the event's team and a new task is created on that event" do
      #   company_user.update_attributes({notifications_settings: ['new_unassigned_team_task_app']})
      #   event = FactoryGirl.create(:event, company: company)
      #   event.users << company_user
      #   task = FactoryGirl.create(:task, title: 'The task title', event: event)

      #   Sunspot.commit

      #   get 'notifications', id: company_user.to_param, format: :json

      #   notifications = JSON.parse(response.body)
      #   notifications.should include({"message"=>"A new task was created for your event: The task title", "level"=>"grey", "url"=>"/tasks/my_teams?q=task%2C#{task.id}&notifid=#{Notification.last.id}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"new_team_task", "task_id" => task.id})
      # end

      it "should return a notification if there is a new task for the user" do
        company_user.update_attributes({notifications_settings: ['new_task_assignment_app']})
        Timecop.freeze do
          task = without_current_user do
            FactoryGirl.create(:task,
              title: 'The task title',
              event: FactoryGirl.create(:event, company: company), company_user: company_user)
          end

          get 'notifications', id: company_user.to_param, format: :json

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message"=>"You have a new task", "level"=>"grey", "url"=>"/tasks/mine?new_at=#{timestamp}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"new_task"})
        end
      end

      it "should return a notification if there is a new comment for a user's task" do
        company_user.update_attributes({notifications_settings: ['new_comment_app']})
        task = FactoryGirl.create(:task, title: 'The task title', event: FactoryGirl.create(:event, company: company), company_user: company_user)
        comment = FactoryGirl.create(:comment, commentable: task)
        comment.update_column(:created_by_id, FactoryGirl.create(:company_user, company: company).user.id)

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"Your task <span>The task title</span> has a new comment", "level"=>"grey", "url"=>"/tasks/mine?q=task%2C#{task.id}#comments-#{task.id}", "unread"=>true, "icon"=>"icon-notification-comment", "type"=>"user_task_comments", "task_id"=>task.id})
      end

      it "should return a notification if there is a new comment for a user's team task" do
        company_user.update_attributes({notifications_settings: ['new_team_comment_app']})
        task = FactoryGirl.create(:task, title: 'The task title', event: FactoryGirl.create(:event, company: company))
        task.event.users << company_user
        comment = FactoryGirl.create(:comment, commentable: task)
        comment.update_column(:created_by_id, company_user.user.id+1)

        get 'notifications', id: company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"Your team's task <span>The task title</span> has a new comment", "level"=>"grey", "url"=>"/tasks/my_teams?q=task%2C#{task.id}#comments-#{task.id}", "unread"=>true, "icon"=>"icon-notification-comment", "type"=>"team_task_comments", "task_id"=>task.id})
      end
    end
  end

  describe "As NOT Super User" do
    let(:company_user) { FactoryGirl.create(:company_user,
      company: company,
      permissions: [[:view_list, 'Event']],
      role: FactoryGirl.create(:non_admin_role, company: company)) }
    let(:campaign){ FactoryGirl.create(:campaign, company: company) }
    let(:place){ FactoryGirl.create(:place) }

    describe "GET 'notifications'" do
      let(:timestamp) { Time.now.to_datetime.strftime('%Q').to_i }
      it "should return a notification if a user is added to a event's team" do
        Timecop.freeze do
          company_user.update_attributes({notifications_settings: ['new_event_team_app']})
          company_user.places << place
          campaign.places << place
          company_user.campaigns << campaign
          event = without_current_user{ FactoryGirl.create(:event, company: company, place: place) }
          event.users << company_user
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "You have a new event", "level" => "grey", "url" => events_path(new_at: timestamp, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_event"})
        end
      end

      it "should return a notification if the user have a late event recap" do
        company_user.update_attributes({notifications_settings: ['event_recap_late_app']})
        company_user.places << place
        campaign.places << place
        campaign.users << company_user
        event = FactoryGirl.create(:late_event, company: company, campaign: campaign, place: place)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_late"})
      end

      it "should return a notification if the user have a submitted event recap that is waiting for approval" do
        company_user.update_attributes({notifications_settings: ['event_recap_pending_approval_app']})
        company_user.places << place
        campaign.places << place
        campaign.users << company_user
        event = FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_pending"})
      end

      it "should return a notification if the user have a due event recap" do
        company_user.update_attributes({notifications_settings: ['event_recap_due_app']})
        company_user.places << place
        campaign.places << place
        campaign.users << company_user
        event = FactoryGirl.create(:due_event, company: company, campaign: campaign, place: place)
        event.users << company_user
        Sunspot.commit

        get 'notifications', id: company_user.to_param, format: :json

        expect(response).to be_success

        notifications = JSON.parse(response.body)
        expect(notifications).to include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active&user%5B%5D=#{company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_due"})
      end

      describe "when notification policy is set to EVENT_ALERT_POLICY_ALL" do
        let(:campaign) { FactoryGirl.create(:campaign, company: company) }
        let(:place) { FactoryGirl.create(:place, city: 'Los Angeles', state: 'CA', country: 'US') }
        let(:city) { FactoryGirl.create(:city, name: 'Los Angeles', state: 'CA', country: 'US' ) }
        before { company_user.places << city }
        before { company.update_attribute(:settings, {event_alerts_policy: Notification::EVENT_ALERT_POLICY_ALL}) }
        before { campaign.places << city }
        before { campaign.users << company_user }

        it "should notify all users about late events that they have access to" do
          company_user.update_attributes({notifications_settings: ['event_recap_late_app']})
          without_current_user { FactoryGirl.create(:late_event, campaign: campaign, place: place) }

          # Another events the user should not have access to
          without_current_user { FactoryGirl.create(:late_event, campaign: campaign) }
          without_current_user { FactoryGirl.create(:late_event, place: place) }
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_late"})
        end

        it "should return a notification if the user have a submitted event recap that is waiting for approval" do
          company_user.update_attributes({notifications_settings: ['event_recap_pending_approval_app']})
          without_current_user { FactoryGirl.create(:submitted_event, campaign: campaign, place: place) }

          # Another events the user should not have access to
          without_current_user { FactoryGirl.create(:submitted_event, campaign: campaign) }
          without_current_user { FactoryGirl.create(:submitted_event, place: place) }
          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_pending"})
        end

        it "should return a notification if the user have a due event recap" do
          company_user.update_attributes({notifications_settings: ['event_recap_due_app']})
          without_current_user { FactoryGirl.create(:due_event, campaign: campaign, place: place) }

          # Another events the user should not have access to
          without_current_user { FactoryGirl.create(:due_event, campaign: campaign) }
          without_current_user { FactoryGirl.create(:due_event, place: place) }

          Sunspot.commit

          get 'notifications', id: company_user.to_param, format: :json

          expect(response).to be_success

          notifications = JSON.parse(response.body)
          expect(notifications).to include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_due"})
        end
      end
    end
  end
end