require 'spec_helper'

describe CommentsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:event) {FactoryGirl.create(:event, company: @company)}
  let(:task) {FactoryGirl.create(:task, event: event)}
  let(:event_comment) {FactoryGirl.create(:comment, commentable: event)}
  let(:task_comment) {FactoryGirl.create(:comment, commentable: task)}

  describe "GET 'index'" do
    it "should be able index task's comments" do
      task_comment.save
      get 'index', task_id: task.to_param, format: :js
      response.should be_success
      response.should render_template('comments/index')
      response.should render_template('comments/_comments_list')
      response.should render_template('comments/_comment')
    end
  end

  describe "POST 'create'" do
    it "should be able to create a comment for a event" do
      expect {
        post 'create', event_id: event.to_param, comment: {content: 'this is a test'}, format: :js
      }.to change(Comment, :count).by(1)
      response.should be_success
      response.should render_template('create')
      comment = Comment.last
      comment.content.should == 'this is a test'
      event.comments.should == [comment]
    end

    it "should be able to create a comment for a task" do
      expect {
        post 'create', task_id: task.to_param, comment: {content: 'this is a test'}, format: :js
      }.to change(Comment, :count).by(1)
      response.should be_success
      response.should render_template('create')
      comment = Comment.last
      comment.content.should == 'this is a test'
      task.comments.should == [comment]
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', event_id: event.to_param, comment: {content: ''}, format: :js
      }.should_not change(Comment, :count)
      response.should render_template(:create)
      response.should render_template('comments/_form')
      assigns(:comment).errors.count > 0
    end

    it "should be able to create a comment for an assigned task and send a SMS to the owner" do
      Timecop.freeze do
        with_resque do
          @company_user.update_attributes({notifications_settings: ['new_comment_sms', 'new_comment_email']}, without_protection: true)
          task.update_attributes({company_user_id: @company_user.to_param}, without_protection: true)
          message = "You have a new comment http://localhost:5100/tasks/mine?q=task%2C#{task.id}#comments-#{task.id}"
          UserMailer.should_receive(:notification).with(@company_user, "New Comment", message).and_return(double(deliver: true))
          expect {
            post 'create', task_id: task.to_param, comment: {content: 'this is a test'}, format: :js
          }.to change(Comment, :count).by(1)
          comment = Comment.last
          comment.content.should == 'this is a test'
          task.comments.should == [comment]
          open_last_text_message_for @user.phone_number
          current_text_message.should have_body message
        end
      end
    end

    it "should be able to create a comment for a unassigned task and send a SMS to the event team members" do
      Timecop.freeze do
        with_resque do
          @company_user.update_attributes({notifications_settings: ['new_team_comment_sms', 'new_team_comment_email']}, without_protection: true)
          other_user = FactoryGirl.create(:company_user, company_id: @company.id, notifications_settings: ['new_team_comment_sms'])
          task.update_attributes({event_id: event.to_param}, without_protection: true)
          event.users << @company_user
          event.users << other_user
          message = "You have a new team comment http://localhost:5100/tasks/mine?q=task%2C#{task.id}#comments-#{task.id}"
          UserMailer.should_receive(:notification).with(@company_user, "New Team Comment", message).and_return(double(deliver: true))
          expect {
            post 'create', task_id: task.to_param, comment: {content: 'this is a test'}, format: :js
          }.to change(Comment, :count).by(1)
          comment = Comment.last
          comment.content.should == 'this is a test'
          task.comments.should == [comment]
          open_last_text_message_for @user.phone_number
          current_text_message.should have_body message
          open_last_text_message_for other_user.user.phone_number
          current_text_message.should have_body message
        end
      end
    end
  end

  describe "PUT 'update'" do
    it "should update the event comment attributes" do
      put 'update', event_id: event.to_param, id: event_comment.to_param, comment: {content: 'new content for comment'}, format: :js
      response.should be_success
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      event_comment.reload.content.should == 'new content for comment'
    end
  end

  describe "GET 'edit'" do
    it "should render the comment form for a event comment" do
      get 'edit', event_id: event.to_param, id: event_comment.to_param, format: :js
      response.should render_template('comments/_form')
      response.should render_template(:form_dialog)
      assigns(:comment).should == event_comment
    end
  end

  describe "GET 'new'" do
    it "should render the comment form for a event comment" do
      get 'new', event_id: event.to_param, format: :js
      response.should render_template('comments/_form')
      response.should render_template(:form_dialog)
      assigns(:comment).new_record?.should be_true
      assigns(:comment).commentable.should == event
    end
  end
end