require 'spec_helper'

describe Api::V1::TasksController do
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
      response.should be_success
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
      response.should be_success
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
      response.should be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 2
      expect(result['total']).to eql 2
      expect(result['page']).to eql 1
      expect(result['results'].map{|r| r['id']}).to match_array(tasks.map(&:id))
      expect(result['results'].first.keys).to match_array(["active", "completed", "due_at", "id", "status", "title", "user"])
    end

    it "return a list of tasks for the user's team" do
      tasks = FactoryGirl.create_list(:task, 2, event: event)
      # Create some more tasks that should not be returned by the response
      FactoryGirl.create_list(:task, 2, event: event, company_user: company_user)
      FactoryGirl.create_list(:task, 2, event: FactoryGirl.create(:event, company: company))
      event.users << company_user
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, scope: 'teams', format: :json
      response.should be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 2
      expect(result['total']).to eql 2
      expect(result['page']).to eql 1
      expect(result['results'].map{|r| r['id']}).to match_array(tasks.map(&:id))
      expect(result['results'].first.keys).to match_array(["active", "completed", "due_at", "id", "status", "title", "user"])
    end
  end

end