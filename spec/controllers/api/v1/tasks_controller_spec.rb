require 'rails_helper'

describe Api::V1::TasksController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.company_users.first }
  let(:company) { company_user.company }
  let(:event)  { FactoryGirl.create(:event, company: company) }

  describe "GET 'index'", search: true do
    it "return a list of tasks for a event" do
      tasks = FactoryGirl.create_list(:task, 2, event: event)
      FactoryGirl.create_list(:task, 2, event: FactoryGirl.create(:event, company: company))
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 2
      expect(result['total']).to eql 2
      expect(result['page']).to eql 1
      expect(result['results'].first.keys).to match_array(["active", "completed", "due_at", "id", "status", "title", "user"])
    end

    it "should filter by state" do
      active_task = FactoryGirl.create(:task, active: true, event: event)
      inactive_task = FactoryGirl.create(:task, active: false, event: event)
      FactoryGirl.create_list(:task, 2, event: FactoryGirl.create(:event, company: company))
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, status: ['Active'], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 1
      expect(result['total']).to eql 1
      expect(result['page']).to eql 1
      expect(result['results'].first['id']).to eq active_task.id
    end

    it "return a list of tasks for the user" do
      tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: company_user)
      FactoryGirl.create_list(:task, 2, event: event)
      FactoryGirl.create_list(:task, 2, event: FactoryGirl.create(:event, company: company))
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, scope: 'user', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 2
      expect(result['total']).to eql 2
      expect(result['page']).to eql 1
      expect(result['results'].map{|r| r['id']}).to match_array(tasks.map(&:id))
      expect(result['results'].first.keys).to match_array(["active", "completed", "due_at", "id", "status", "title", "user"])
    end

    it "return a list of tasks for the user's team" do
      event.users << company_user
      tasks = FactoryGirl.create_list(:task, 2, event: event)
      another_event = FactoryGirl.create(:event, company: company,user_ids:[])
      another_event.users = []
      # Create some more tasks that should not be returned by the response
      FactoryGirl.create_list(:task, 2, event: another_event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, scope: 'teams', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 2
      expect(result['total']).to eql 2
      expect(result['page']).to eql 1
      expect(result['results'].map{|r| r['id']}).to match_array(tasks.map(&:id))
      expect(result['results'].first.keys).to match_array(["active", "completed", "due_at", "id", "status", "title", "user"])
    end
  end

  describe "GET 'comments'" do
    it "returns the list of comments for the task" do
      event = FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company))
      task = FactoryGirl.create(:task, event: event)
      comment1 = FactoryGirl.create(:comment, content: 'Comment #1', commentable: task, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = FactoryGirl.create(:comment, content: 'Comment #2', commentable: task, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      event.save
      Sunspot.commit

      get 'comments', auth_token: user.authentication_token, company_id: company.to_param, id: task.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result).to eq([{
                         'id' => comment1.id,
                         'content' => 'Comment #1',
                         'created_at' => '2013-08-22T11:59:00.000-07:00',
                         'created_by' => {
                           'id' => comment1.created_by_id,
                           'full_name' => comment1.user.full_name
                          }
                        },
                        {
                         'id' => comment2.id,
                         'content' => 'Comment #2',
                         'created_at' => '2013-08-23T09:15:00.000-07:00',
                         'created_by' => {
                           'id' => comment2.created_by_id,
                           'full_name' => comment2.user.full_name
                          }
                        }])
    end
  end
end