require 'rails_helper'

RSpec.describe Api::V1::ActivitiesController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.company_users.first }
  let(:company) { user.company_users.first.company }
  let(:activity_type) { create(:activity_type, company: company) }
  let(:event) { create(:event, company: company) }

  before { set_api_authentication_headers user, company }

  describe "GET 'new'", search: true do
    it 'returns only the user/date if no fields have been aded to the activity type' do
      get :new, activity_type_id: activity_type.id, format: :json
      results = JSON.parse(response.body)
      expect(results.count).to eql 1
      expect(results.first).to include({
        'name' => 'User/Date', 'value' => nil,
        'type' => 'FormField::UserDate', 'settings' => nil,
        'ordering' => 1, 'required' => nil, 'kpi_id' => nil })
    end

    it 'returns the fields have been aded to the activity type' do
      create(:form_field_text, fieldable: activity_type, ordering: 2)
      create(:form_field_number, fieldable: activity_type, ordering: 3)
      get :new, activity_type_id: activity_type.id, format: :json
      results = JSON.parse(response.body)
      expect(results.count).to eql 3
      expect(results.map { |at|  at['type'] }).to eql [
        'FormField::UserDate', 'FormField::Text', 'FormField::Number']
    end
  end

  describe "GET 'show'", search: true do
    let(:activity) { create(:activity, activity_type: activity_type, company_user: company_user, activitable: event) }
    before { event.campaign.activity_types << activity_type }

    it 'retruns the activity info' do
      get :show, id: activity.id, format: :json
      results = JSON.parse(response.body)
      expect(results['id']).to eql activity.id
      expect(results['company_user']['id']).to eql activity.company_user_id
      expect(results['company_user']['name']).to eql activity.company_user.full_name
    end

    it 'returns only the user/date if no fields have been aded to the activity type' do
      get :show, id: activity.id, format: :json
      results = JSON.parse(response.body)
      expect(results['data'].count).to eql 1
      expect(results['data'].first).to include({
        'name' => 'User/Date', 'value' => nil,
        'type' => 'FormField::UserDate', 'settings' => nil,
        'ordering' => 1, 'required' => nil, 'kpi_id' => nil })
    end

    it 'returns the fields have been aded to the activity type' do
      create(:form_field_text, fieldable: activity_type, ordering: 2)
      create(:form_field_number, fieldable: activity_type, ordering: 3)
      get :show, id: activity.id, format: :json
      results = JSON.parse(response.body)
      expect(results['data'].count).to eql 3
      expect(results['data'].map { |at|  at['type'] }).to eql [
        'FormField::UserDate', 'FormField::Text', 'FormField::Number']
    end
  end
end
