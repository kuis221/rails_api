require 'rails_helper'

describe TasksController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:event) { create(:event, company_id: @company.id) }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', event_id: event.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', event_id: event.to_param, format: :js
      expect(response).to be_success
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', event_id: event.to_param, task: { title: 'Some test task', due_at: '05/12/2020', company_user_id: @company_user.to_param }, format: :js
      end.to change(Task, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', event_id: event.to_param, format: :js
      end.not_to change(Task, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:event).errors.count > 0
    end

    it 'should assign the correct event id' do
      expect do
        xhr :post, 'create', event_id: event.to_param, task: { title: 'Some test task', due_at: '05/23/2020', company_user_id: @company_user.to_param }, format: :js
      end.to change(Task, :count).by(1)
      expect(assigns(:event)).to eq(event)
      expect(assigns(:task).event_id).to eq(event.id)
      expect(assigns(:task).due_at.to_s).to eq('05/23/2020 00:00:00')
    end

    it 'should assign the user to the task and send a SMS to the assigned user' do
      Timecop.freeze do
        with_resque do
          @company_user = create(:company_user,
                                             company_id: @company.id, notifications_settings: %w(new_task_assignment_sms new_task_assignment_email),
                                             user_attributes: { phone_number_verified: true })
          message = "You have a new task http://localhost:5100/tasks/mine?new_at=#{Time.now.to_i}"
          expect(UserMailer).to receive(:notification).with(@company_user.id, 'New Task Assignment', message).and_return(double(deliver: true))
          expect do
            xhr :post, 'create', event_id: event.to_param, task: { title: 'Some test task', due_at: '05/23/2020', company_user_id: @company_user.to_param }, format: :js
          end.to change(Task, :count).by(1)
          expect(assigns(:task).company_user_id).to eq(@company_user.id)
          open_last_text_message_for @user.phone_number
          expect(current_text_message).to have_body message
        end
      end
    end
  end

  describe "GET 'edit'" do
    let(:task) { create(:task, event_id: event.id, company_user: @company_user) }
    it 'returns http success' do
      xhr :get, 'edit', company_user_id: @company_user.to_param, id: task.to_param, format: :js
      expect(response).to be_success
      expect(assigns(:company_user)).to eq(@company_user)
      expect(assigns(:task)).to eq(task)
    end
  end

  describe "PUT 'update'" do
    let(:task) { create(:task, event_id: event.id, company_user: @company_user) }
    it 'must update the task attributes' do
      xhr :put, 'update', event_id: event.to_param, id: task.to_param, task: { title: 'New task title', due_at: '12/31/2013', company_user_id: @company_user.to_param }, format: :js
      expect(assigns(:task)).to eq(task)
      expect(response).to be_success
      task.reload
      expect(task.title).to eq('New task title')
      expect(task.due_at).to eq(Time.zone.parse('2013-12-31 00:00:00'))
      expect(task.company_user_id).to eq(@company_user.id)
    end

    it 'must update the task completed attribute' do
      xhr :put, 'update', event_id: event.to_param, id: task.to_param, task: { completed: true }, format: :js
      expect(assigns(:task)).to eq(task)
      expect(response).to be_success
      task.reload
      expect(task.completed).to eq(true)
    end
  end

  describe "GET 'items'" do
    it 'return http sucess for user tasks' do
      get 'items', scope: 'user'
      expect(response).to be_success
    end

    it 'return http sucess for user teams' do
      get 'items', scope: 'teams'
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    before(:each) do
      @team = create(:team, company: @company)
      @company_user.teams << @team
    end

    describe 'html requests' do
      it 'should be sucess' do
        get 'index', scope: 'user'
        expect(response).to be_success
      end

      it 'should be sucess' do
        get 'index', scope: 'teams'
        expect(response).to be_success
      end
    end
  end
end
