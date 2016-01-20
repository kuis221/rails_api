require 'rails_helper'

describe Api::V1::TasksController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.company_users.first }
  let(:company) { company_user.company }
  let(:event)  { create(:event, company: company) }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'", search: true do
    it 'return a list of tasks for a event', :show_in_doc do
      create_list(:task, 2, event: event)
      create_list(:task, 2, event: create(:event, company: company))
      Sunspot.commit

      get :index, event_id: event.id, format: :json
      expect(response).to be_success
      expect(json['results'].count).to eql 2
      expect(json['total']).to eql 2
      expect(json['page']).to eql 1
      expect(json['results'].first.keys).to match_array(%w(active completed due_at id event_id status title user))
    end

    it 'should filter by state' do
      active_task = create(:task, active: true, event: event)
      create(:task, active: false, event: event)
      create_list(:task, 2, event: create(:event, company: company))
      Sunspot.commit

      get :index, event_id: event.id, status: ['Active'], format: :json
      expect(response).to be_success

      expect(json['results'].count).to eql 1
      expect(json['total']).to eql 1
      expect(json['page']).to eql 1
      expect(json['results'].first['id']).to eq active_task.id
    end

    it 'return a list of tasks for the user' do
      tasks = create_list(:task, 2, event: event, company_user: company_user)
      create_list(:task, 2, event: event)
      create_list(:task, 2, event: create(:event, company: company))
      Sunspot.commit

      get :index, scope: 'user', format: :json
      expect(response).to be_success

      expect(json['results'].count).to eql 2
      expect(json['total']).to eql 2
      expect(json['page']).to eql 1
      expect(json['results'].map { |r| r['id'] }).to match_array(tasks.map(&:id))
      expect(json['results'].first.keys).to match_array(%w(active completed due_at id event_id status title user))
    end

    it "return a list of tasks for the user's team" do
      event.users << company_user
      tasks = create_list(:task, 2, event: event)
      another_event = create(:event, company: company, user_ids: [])
      another_event.users = []
      # Create some more tasks that should not be returned by the response
      # Updating the "company id" user to avoid include them in the results
      task = create(:task, event: another_event)
      task.update_attributes(company_user_id: company_user.id)
      task = create(:task, event: another_event)
      task.update_attributes(company_user_id: company_user.id)

      Sunspot.commit

      get :index, scope: 'teams', format: :json
      expect(response).to be_success

      expect(json['results'].count).to eql 2
      expect(json['total']).to eql 2
      expect(json['page']).to eql 1
      expect(json['results'].map { |r| r['id'] }).to match_array(tasks.map(&:id))
      expect(json['results'].first.keys).to match_array(%w(active completed due_at id event_id status title user))
    end
  end

  describe "POST 'create'" do
    it 'creates the task linked to a event', :show_in_doc do
      expect do
        post 'create', event_id: event.to_param, format: :json,
                       task: {
                         title: 'Some test task', due_at: '05/12/2020',
                         active: 'false', company_user_id: company_user.to_param }
      end.to change(Task, :count).by(1)
      expect(response).to be_success
      expect(json['title']).to eql 'Some test task'
      expect(json['event_id']).to eql event.id
      expect(json['user']['id']).to eql company_user.id
      expect(json['due_at']).to eql '05/12/2020'
      expect(json['active']).to be_falsey
      expect(json['status']).to eql %w(Inactive Assigned Incomplete)
    end

    it 'creates the task linked assigned to a user but not to a event' do
      expect do
        post 'create', format: :json,
                       task: {
                         title: 'Some test task', due_at: '05/12/2020',
                         active: false, company_user_id: company_user.to_param }
      end.to change(Task, :count).by(1)
      expect(response).to be_success
      expect(json['title']).to eql 'Some test task'
      expect(json['due_at']).to eql '05/12/2020'
      expect(json['status']).to eql %w(Inactive Assigned Incomplete)
      expect(json['user']['id']).to eql company_user.id
      expect(json['event_id']).to be_nil
    end

    it 'should return errors' do
      expect do
        post 'create', event_id: event.to_param, format: :json
        expect(response.code).to eql '400'
      end.not_to change(Task, :count)
      expect(json['success']).to be_falsey
      expect(json['info']).to eql 'Missing parameter task'
    end

    it 'should assign the user to the task and send a SMS to the assigned user', :inline_jobs do
      Timecop.freeze do
        company_user = create(:company_user,
                              company_id: company.id,
                              notifications_settings: %w(new_task_assignment_sms new_task_assignment_email),
                              user_attributes: { phone_number_verified: true })
        message = "You have a new task http://localhost:5100/tasks/mine?new_at=#{Time.now.to_i}"
        expect(UserMailer).to receive(:notification).with(company_user.id, 'New Task Assignment', message).and_return(double(deliver: true))
        expect do
          post 'create', event_id: event.to_param, format: :json,
                         task: { title: 'Some test task', due_at: '05/23/2020',
                                 company_user_id: company_user.to_param }
        end.to change(Task, :count).by(1)
        expect(assigns(:task).company_user_id).to eq(company_user.id)
        open_last_text_message_for user.phone_number
        expect(current_text_message).to have_body message
      end
    end
  end

  describe "GET 'show'" do
    let!(:task) { create(:task, event: event, company_user: company_user) }

    it 'returns the task details', :show_in_doc do
      get :show, id: task.id, format: :json
      expect(response).to be_success
      expect(json['title']).to eql task.title
    end
  end

  describe "PUT 'update'" do
    let!(:task) { create(:task) }

    it 'updates the task linked to a event', :show_in_doc do
      expect do
        post 'update', id: task.to_param, format: :json,
                       task: {
                         title: 'My new title', due_at: '05/12/2020',
                         active: false, company_user_id: company_user.to_param }
      end.to_not change(Task, :count)
      expect(response).to be_success
      expect(json['title']).to eql 'My new title'
      expect(json['user']['id']).to eql company_user.id
      expect(json['due_at']).to eql '05/12/2020'
      expect(json['status']).to eql %w(Inactive Assigned Incomplete)
    end
  end
end
