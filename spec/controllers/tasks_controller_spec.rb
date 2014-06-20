require 'spec_helper'

describe TasksController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:event) { FactoryGirl.create(:event, company_id: @company.id) }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', event_id: event.to_param, format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('form')
    end
  end

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

    it "should assign the user to the task and send a SMS to the assigned user" do
      Timecop.freeze do
        with_resque do
          @company_user = FactoryGirl.create(:company_user, company_id: @company.id, notifications_settings: ['new_task_assignment_sms', 'new_task_assignment_email'])
          message = "You have a new task http://localhost:5100/tasks/mine?new_at=#{Time.now.to_i}"
          UserMailer.should_receive(:notification).with(@company_user, "New Task Assignment", message).and_return(double(deliver: true))
          expect {
            post 'create', event_id: event.to_param, task: {title: "Some test task", due_at: '05/23/2020', company_user_id: @company_user.to_param}, format: :js
          }.to change(Task, :count).by(1)
          assigns(:task).company_user_id.should == @company_user.id
          open_last_text_message_for @user.phone_number
          current_text_message.should have_body message
        end
      end
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
    let(:task){ FactoryGirl.create(:task, event_id: event.id, company_user: @company_user) }
    it "must update the task attributes" do
      put 'update', event_id: event.to_param, id: task.to_param, task: {title: 'New task title', due_at: '12/31/2013', company_user_id: @company_user.to_param}, format: :js
      assigns(:task).should == task
      response.should be_success
      task.reload
      task.title.should == 'New task title'
      task.due_at.should == Time.zone.parse('2013-12-31 00:00:00')
      task.company_user_id.should == @company_user.id
    end

    it "must update the task completed attribute" do
      put 'update', event_id: event.to_param, id: task.to_param, task: {completed: true}, format: :js
      assigns(:task).should == task
      response.should be_success
      task.reload
      task.completed.should == true
    end
  end

  describe "GET 'items'" do
    it "return http sucess for user tasks" do
      get 'items', scope: 'user'
      response.should be_success
    end

    it "return http sucess for user teams" do
      get 'items', scope: 'teams'
      response.should be_success
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
  end
end