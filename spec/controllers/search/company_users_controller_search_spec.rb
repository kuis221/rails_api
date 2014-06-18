require 'spec_helper'

describe CompanyUsersController, search: true do
  describe "As Super User" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.current_company
      @company_user = @user.current_company_user
    end

    describe "GET 'autocomplete'" do
      it "should return the correct buckets in the right order" do
        Sunspot.commit
        get 'autocomplete'
        response.should be_success

        buckets = JSON.parse(response.body)
        buckets.map{|b| b['label']}.should == ['Users','Teams', 'Roles', 'Campaigns', 'Places']
      end

      it "should return the users in the User Bucket" do
        user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'Users'}.first
        people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
      end


      it "should return the teams in the Teams Bucket" do
        team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'sp'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'Teams'}.first
        people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}]
      end

      it "should return the campaigns in the Campaigns Bucket" do
        campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        response.should be_success

        buckets = JSON.parse(response.body)
        campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
        campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
      end

      it "should return the roles in the Roles Bucket" do
        role = FactoryGirl.create(:role, name: 'Campaing Staff', company: @company)
        Sunspot.commit

        get 'autocomplete', q: 'staff'
        response.should be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.select{|b| b['label'] == 'Roles'}.first
        places_bucket['value'].should == [{"label"=>"Campaing <i>Staff</i>", "value"=>role.id.to_s, "type"=>"role"}]
      end

      it "should return the venues in the Places Bucket" do
        Place.any_instance.should_receive(:fetch_place_data).and_return(true)
        venue = FactoryGirl.create(:venue, company_id: @company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
        Sunspot.commit

        get 'autocomplete', q: 'mot'
        response.should be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
        places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}]
      end
    end

    describe "GET 'notifications'" do
      it "should return a notification if a user is added to a campaign" do
        Timecop.freeze do
          campaign = FactoryGirl.create(:campaign, company: @company)
          @company_user.campaigns << campaign
          Sunspot.commit

          get 'notifications', id: @company_user.to_param, format: :json

          response.should be_success

          notifications = JSON.parse(response.body)
          notifications.should include({"message" => "You have a new campaign", "level" => "grey", "url" => campaigns_path(new_at: Time.now.to_i), "unread" => true, "icon" => "icon-notification-campaign", "type"=>"new_campaign"})
        end
      end

      it "should return a notification if a user is added to a event's team" do
        Timecop.freeze do
          event = FactoryGirl.create(:event, company: @company)
          event.users << @company_user
          Sunspot.commit

          get 'notifications', id: @company_user.to_param, format: :json

          response.should be_success

          notifications = JSON.parse(response.body)
          notifications.should include({"message" => "You have a new event", "level" => "grey", "url" => events_path(new_at: Time.now.to_i, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_event"})
        end
      end

      it "should return a notification if a user team is added to a event's team" do
        Timecop.freeze do
          event1 = FactoryGirl.create(:event, company: @company)
          @company_user.notifications.delete_all
          team1 = FactoryGirl.create(:team, name: 'Team A', company: @company)
          team1.users << @company_user
          event1.teams << team1
          Sunspot.commit

          get 'notifications', id: @company_user.to_param, format: :json

          response.should be_success

          notifications = JSON.parse(response.body)
          notifications.should include({"message" => "Your team Team A has a new event", "level" => "grey", "url" => events_path(notification: 'new_team_event', team: [team1.id], new_at: Time.now.to_i, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_team_event"})

          #New user team added to a new event, different message is obtained
          event2 = FactoryGirl.create(:event, company: @company)
          team2 = FactoryGirl.create(:team, name: 'Team B', company: @company)
          team2.users << @company_user
          event2.teams << team2
          Sunspot.commit

          get 'notifications', id: @company_user.to_param, format: :json

          response.should be_success

          notifications = JSON.parse(response.body)
          notifications.should include({"message" => "You teams Team A, Team B have 2 new events", "level" => "grey", "url" => events_path(notification: 'new_team_event', team: [team1.id, team2.id], new_at: Time.now.to_i, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_team_event"})
        end
      end

      it "should return a notification if the user have a late event recap" do
        event = FactoryGirl.create(:late_event, company: @company)
        event.users << @company_user
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_late"})
      end

      it "should NOT return a notification if the user is not part of the event's team" do
        without_current_user do
          event = FactoryGirl.create(:late_event, company: @company)
        end
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should == []
      end

      it "should return a notification if the user have a submitted event recap that is waiting for approval" do
        event = FactoryGirl.create(:submitted_event, company: @company)
        event.users << @company_user
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_pending"})
      end

      it "should return a notification if the user have a due event recap" do
        event = FactoryGirl.create(:due_event, company: @company)
        event.users << @company_user
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_due"})
      end

      it "should return a notification if the user has is assigned to a task that is late" do
        event = FactoryGirl.create(:event, company: @company)
        task = FactoryGirl.create(:late_task, event: event, company_user_id: @company_user.id)

        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"You have one late task", "level"=>"red", "url"=>"/tasks/mine?end_date=&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"user_tasks_late"})
      end

      it "should return a notification if the user is part of the event's team that have a late task" do
        event = FactoryGirl.create(:event, company: @company)
        event.users << @company_user
        task = FactoryGirl.create(:late_task, event: event, company_user_id: nil)

        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"Your team has one late task", "level"=>"red", "url"=>"/tasks/my_teams?end_date=&not_assigned_to%5B%5D=#{@company_user.id}&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&team_members%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"team_tasks_late"})
      end

      # it "should return a notification if the user is part of the event's team and a new task is created on that event" do
      #   event = FactoryGirl.create(:event, company: @company)
      #   event.users << @company_user
      #   task = FactoryGirl.create(:task, title: 'The task title', event: event)

      #   Sunspot.commit

      #   get 'notifications', id: @company_user.to_param, format: :json

      #   notifications = JSON.parse(response.body)
      #   notifications.should include({"message"=>"A new task was created for your event: The task title", "level"=>"grey", "url"=>"/tasks/my_teams?q=task%2C#{task.id}&notifid=#{Notification.last.id}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"new_team_task", "task_id" => task.id})
      # end

      it "should return a notification if there is a new task for the user" do
        Timecop.freeze do
          task = without_current_user do
            FactoryGirl.create(:task,
              title: 'The task title',
              event: FactoryGirl.create(:event, company: @company), company_user: @company_user)
          end

          get 'notifications', id: @company_user.to_param, format: :json

          notifications = JSON.parse(response.body)
          notifications.should include({"message"=>"You have a new task", "level"=>"grey", "url"=>"/tasks/mine?new_at=#{Time.now.to_i}", "unread"=>true, "icon"=>"icon-notification-task", "type"=>"new_task"})
        end
      end

      it "should return a notification if there is a new comment for a user's task" do
        task = FactoryGirl.create(:task, title: 'The task title', event: FactoryGirl.create(:event, company: @company), company_user: @company_user)
        comment = FactoryGirl.create(:comment, commentable: task)
        comment.update_column(:created_by_id, FactoryGirl.create(:company_user, company: @company).user.id)

        get 'notifications', id: @company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"Your task <span>The task title</span> has a new comment", "level"=>"grey", "url"=>"/tasks/mine?q=task%2C#{task.id}#comments-#{task.id}", "unread"=>true, "icon"=>"icon-notification-comment", "type"=>"user_task_comments", "task_id"=>task.id})
      end

      it "should return a notification if there is a new comment for a user's team task" do
        task = FactoryGirl.create(:task, title: 'The task title', event: FactoryGirl.create(:event, company: @company))
        task.event.users << @company_user
        comment = FactoryGirl.create(:comment, commentable: task)
        comment.update_column(:created_by_id, @company_user.user.id+1)

        get 'notifications', id: @company_user.to_param, format: :json

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"Your team's task <span>The task title</span> has a new comment", "level"=>"grey", "url"=>"/tasks/my_teams?q=task%2C#{task.id}#comments-#{task.id}", "unread"=>true, "icon"=>"icon-notification-comment", "type"=>"team_task_comments", "task_id"=>task.id})
      end
    end
  end

  describe "As NOT Super User" do
    before(:each) do
      @company = FactoryGirl.create(:company)
      @company_user = FactoryGirl.create(:company_user,
              company: @company,
              role: FactoryGirl.create(:role, is_admin: false, company: @company))
      @user = @company_user.user
      sign_in @user
    end

    let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
    let(:place){ FactoryGirl.create(:place) }

    describe "GET 'notifications'" do
      it "should return a notification if a user is added to a event's team" do
        Timecop.freeze do
          @company_user.role.permission_for(:view_list, Event).save
          @company_user.places << place
          campaign.places << place
          campaign.users << @company_user
          event = FactoryGirl.create(:event, company: @company, place: place)
          event.users << @company_user
          Sunspot.commit

          get 'notifications', id: @company_user.to_param, format: :json

          response.should be_success

          notifications = JSON.parse(response.body)
          notifications.should include({"message" => "You have a new event", "level" => "grey", "url" => events_path(new_at: Time.now.to_i, end_date: '', start_date: ''), "unread" => true, "icon" => "icon-notification-event", "type"=>"new_event"})
        end
      end

      it "should return a notification if the user have a late event recap" do
        @company_user.role.permission_for(:view_list, Event).save
        @company_user.places << place
        campaign.places << place
        campaign.users << @company_user
        event = FactoryGirl.create(:late_event, company: @company, campaign: campaign, place: place)
        event.users << @company_user
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_late"})
      end

      it "should return a notification if the user have a submitted event recap that is waiting for approval" do
        @company_user.role.permission_for(:view_list, Event).save
        @company_user.places << place
        campaign.places << place
        campaign.users << @company_user
        event = FactoryGirl.create(:submitted_event, company: @company, campaign: campaign, place: place)
        event.users << @company_user
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_pending"})
      end

      it "should return a notification if the user have a due event recap" do
        @company_user.role.permission_for(:view_list, Event).save
        @company_user.places << place
        campaign.places << place
        campaign.users << @company_user
        event = FactoryGirl.create(:due_event, company: @company, campaign: campaign, place: place)
        event.users << @company_user
        Sunspot.commit

        get 'notifications', id: @company_user.to_param, format: :json

        response.should be_success

        notifications = JSON.parse(response.body)
        notifications.should include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event", "type"=>"event_recaps_due"})
      end
    end
  end
end