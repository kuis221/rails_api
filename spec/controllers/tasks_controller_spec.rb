require 'spec_helper'

describe TasksController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  let(:event) { FactoryGirl.create(:event, company_id: @company.id) }

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', event_id: event.to_param, format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', event_id: event.to_param, task: {title: "Some test task", due_at: '05/23/2020', user_id: @user.to_param}, format: :js
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
        post 'create', event_id: event.to_param, task: {title: "Some test task", due_at: '05/23/2020', user_id: @user.to_param}, format: :js
      }.should change(Task, :count).by(1)
      assigns(:event).should == event
      assigns(:task).event_id.should == event.id
      assigns(:task).due_at.to_s.should == '05/23/2020 00:00:00'
    end
  end

  describe "PUT 'update'" do
    let(:task){ FactoryGirl.create(:task) }
    it "must update the task attributes" do
      put 'update', event_id: event.to_param, id: task.to_param, task: {title: 'New task title', due_at: '12/31/2013', user_id: 3}, format: :js
      assigns(:task).should == task
      response.should be_success
      task.reload
      task.title.should == 'New task title'
      task.due_at.should == DateTime.parse('2013-12-31 00:00:00')
      task.user_id.should == 3
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
    it "returns http success" do
      get 'index', event_id: event.to_param, format: :table
      response.should be_success
    end

    describe "datatable requests" do
      it "responds to .table format" do
        get 'index', event_id: event.to_param, format: :table
        response.should be_success
      end

      it "returns the correct structure" do
        FactoryGirl.create_list(:task, 3, event_id: event.id)

        # Events on other events should not be included on the results
        FactoryGirl.create_list(:task, 2, event_id: 9999)
        get 'index', event_id: event.to_param, format: :table
        parsed_body = JSON.parse(response.body)
        parsed_body["sEcho"].should be_nil
        parsed_body["iTotalRecords"].should == 3
        parsed_body["iTotalDisplayRecords"].should == 3
        parsed_body["aaData"].count.should == 3
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