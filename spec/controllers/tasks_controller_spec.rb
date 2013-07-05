require 'spec_helper'

describe TasksController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:event) { FactoryGirl.create(:event, company_id: @company.id) }

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', event_id: event.to_param, format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', event_id: event.to_param, task: {title: "Some test task", due_at: '05/23/2020', company_user_id: @company_user.to_param}, format: :js
      }.should change(Task, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', event_id: event.to_param, format: :js
      }.should_not change(Task, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:event).errors.count > 0
    end

    it "should assign the correct event id" do
      lambda {
        post 'create', event_id: event.to_param, task: {title: "Some test task", due_at: '05/23/2020', company_user_id: @company_user.to_param}, format: :js
      }.should change(Task, :count).by(1)
      assigns(:event).should == event
      assigns(:task).event_id.should == event.id
      assigns(:task).due_at.to_s.should == '05/23/2020 00:00:00'
    end
  end

  describe "GET 'edit'" do
    let(:task) { FactoryGirl.create(:task, event_id: event.id, company_user: @company_user) }
    it "returns http success" do
      get 'edit', company_user_id: @company_user.to_param, id: task.to_param, format: :js
      response.should be_success
      assigns(:company_user).should == @company_user
      assigns(:task).should == task
    end
  end

  describe "PUT 'update'" do
    let(:task){ FactoryGirl.create(:task, event_id: event.id) }
    it "must update the task attributes" do
      put 'update', event_id: event.to_param, id: task.to_param, task: {title: 'New task title', due_at: '12/31/2013', company_user_id: 3}, format: :js
      assigns(:task).should == task
      response.should be_success
      task.reload
      task.title.should == 'New task title'
      task.due_at.should == Time.zone.parse('2013-12-31 00:00:00')
      task.company_user_id.should == 3
    end

    it "must update the task completed attribute" do
      put 'update', event_id: event.to_param, id: task.to_param, task: {completed: true}, format: :js
      assigns(:task).should == task
      response.should be_success
      task.reload
      task.completed.should == true
    end
  end

  describe "GET 'index'" do
    before(:each) do
      @team = FactoryGirl.create(:team)
      @company_user.teams << @team
    end

    describe "html requests" do
      it 'should be sucess' do
        get 'index', scope: 'user'
        response.should be_success
      end

      it 'should be sucess' do
        get 'index', scope: 'teams'
        response.should be_success
      end
    end

    describe "json requests" do
      it "responds to .json format" do
        get 'index', event_id: event.to_param, format: :json
        response.should be_success
      end

      it "returns the correct structure" do
        get 'index', event_id: event.to_param, format: :json
        parsed_body = JSON.parse(response.body)
        parsed_body["total"].should == 0
        parsed_body["items"].count.should == 0
        parsed_body["unassigned"].should == 0
        parsed_body["assigned"].should == 0
        parsed_body["completed"].should == 0
        parsed_body["late"].should == 0
      end
    end

    describe "counters", search: true do
      describe "within an event" do
        it "should return the correct number of completed tasks" do
          FactoryGirl.create_list(:completed_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:uncompleted_task, event: event)
          FactoryGirl.create_list(:completed_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'index', event_id: event.to_param, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body['completed'].should == 3
        end

        it "should return the correct number of assigned tasks" do
          FactoryGirl.create_list(:assigned_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:unassigned_task, event: event)
          FactoryGirl.create_list(:assigned_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'index', event_id: event.to_param, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body['assigned'].should == 3
        end

        it "should return the correct number of unassigned tasks" do
          FactoryGirl.create_list(:unassigned_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:assigned_task, event: event)
          FactoryGirl.create_list(:unassigned_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'index', event_id: event.to_param, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body['unassigned'].should == 3
        end

        it "should return the correct number of late tasks" do
          FactoryGirl.create_list(:late_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:future_task, event: event)
          FactoryGirl.create_list(:late_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'index', event_id: event.to_param, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body['late'].should == 3
        end
      end
    end
  end


  describe "GET 'show'" do
    let(:task) { FactoryGirl.create(:task, event_id: event.id) }
    it "returns http success" do
      get 'show', event_id: event.to_param, id: task.to_param, format: :js
      response.should be_success
      assigns(:event).should == event
      assigns(:task).should == task
    end
  end
end