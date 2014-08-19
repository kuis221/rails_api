require 'rails_helper'

describe CommentsController, :type => :controller do
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
      xhr :get, 'index', task_id: task.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('comments/index')
      expect(response).to render_template('comments/_comments_list')
      expect(response).to render_template('comments/_comment')
    end
  end

  describe "POST 'create'" do
    it "should be able to create a comment for a event" do
      expect {
        xhr :post, 'create', event_id: event.to_param, comment: {content: 'this is a test'}, format: :js
      }.to change(Comment, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      comment = Comment.last
      expect(comment.content).to eq('this is a test')
      expect(event.comments).to eq([comment])
    end

    it "should be able to create a comment for a task" do
      expect {
        xhr :post, 'create', task_id: task.to_param, comment: {content: 'this is a test'}, format: :js
      }.to change(Comment, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      comment = Comment.last
      expect(comment.content).to eq('this is a test')
      expect(task.comments).to eq([comment])
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', event_id: event.to_param, comment: {content: ''}, format: :js
      }.not_to change(Comment, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('comments/_form')
      assigns(:comment).errors.count > 0
    end

    it "should be able to create a comment for an assigned task and send a SMS to the owner" do
      Timecop.freeze do
        with_resque do
          @company_user.update_attributes(
            notifications_settings: ['new_comment_sms', 'new_comment_email'],
            user_attributes: {phone_number_verified: true} )
          task.update_attributes(company_user_id: @company_user.to_param)
          message = "You have a new comment http://localhost:5100/tasks/mine?q=task%2C#{task.id}#comments-#{task.id}"
          expect(UserMailer).to receive(:notification).with(@company_user.id, "New Comment", message).and_return(double(deliver: true))
          expect {
            xhr :post, 'create', task_id: task.to_param, comment: {content: 'this is a test'}, format: :js
          }.to change(Comment, :count).by(1)
          comment = Comment.last
          expect(comment.content).to eq('this is a test')
          expect(task.comments).to eq([comment])
          open_last_text_message_for @user.phone_number
          expect(current_text_message).to have_body message
        end
      end
    end

    it "should be able to create a comment for a unassigned task and send a SMS to the event team members" do
      Timecop.freeze do
        with_resque do
          @company_user.update_attributes(
            notifications_settings: ['new_team_comment_sms', 'new_team_comment_email'],
            user_attributes: {phone_number_verified: true} )

          other_user = FactoryGirl.create(:company_user, company_id: @company.id,
            notifications_settings: ['new_team_comment_sms'],
            user_attributes: {phone_number_verified: true} )

          task.update_attributes(event_id: event.to_param)
          event.users << @company_user
          event.users << other_user
          message = "You have a new team comment http://localhost:5100/tasks/mine?q=task%2C#{task.id}#comments-#{task.id}"
          expect(UserMailer).to receive(:notification).with(@company_user.id, "New Team Comment", message).and_return(double(deliver: true))
          expect {
            xhr :post, 'create', task_id: task.to_param, comment: {content: 'this is a test'}, format: :js
          }.to change(Comment, :count).by(1)
          comment = Comment.last
          expect(comment.content).to eq('this is a test')
          expect(task.comments).to eq([comment])
          open_last_text_message_for @user.phone_number
          expect(current_text_message).to have_body message
          open_last_text_message_for other_user.user.phone_number
          expect(current_text_message).to have_body message
        end
      end
    end
  end

  describe "PUT 'update'" do
    it "should update the event comment attributes" do
      xhr :put, 'update', event_id: event.to_param, id: event_comment.to_param, comment: {content: 'new content for comment'}, format: :js
      expect(response).to be_success
      expect(response).to render_template(:update)
      expect(response).not_to render_template('_form_dialog')

      expect(event_comment.reload.content).to eq('new content for comment')
    end
  end

  describe "GET 'edit'" do
    it "should render the comment form for a event comment" do
      xhr :get, 'edit', event_id: event.to_param, id: event_comment.to_param, format: :js
      expect(response).to render_template('comments/_form')
      expect(response).to render_template('_form_dialog')
      expect(assigns(:comment)).to eq(event_comment)
    end
  end

  describe "GET 'new'" do
    it "should render the comment form for a event comment" do
      xhr :get, 'new', event_id: event.to_param, format: :js
      expect(response).to render_template('comments/_form')
      expect(response).to render_template('_form_dialog')
      expect(assigns(:comment).new_record?).to be_truthy
      expect(assigns(:comment).commentable).to eq(event)
    end
  end
end