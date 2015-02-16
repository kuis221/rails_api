require 'rails_helper'

RSpec.describe Api::V1::ActivitiesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.company_users.first }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company) }
  let(:activity_type) { create(:activity_type, company: company) }
  let(:venue) { create(:venue, place: create(:place), company: company) }
  let(:event) { create(:event, company: company) }
  let(:activity) { create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign, company_user: company_user) }

  before { set_api_authentication_headers user, company }



  describe "PUT 'update'" do
    let(:another_user) { create(:company_user, user: create(:user), company_id: company.id) }
    let(:another_campaign) { create(:campaign, company: company) }

    it 'must update the activity attributes' do
      campaign.activity_types << activity_type
      another_campaign.activity_types << activity_type
      put 'update', venue_id: venue.to_param, id: activity.to_param, activity: {
        campaign_id: another_campaign.id,
        company_user_id: another_user.id,
        activity_date: '02/12/2015' }, format: :json
      expect(assigns(:activity)).to eq(activity)
      expect(response).to be_success
      activity.reload
      expect(activity.campaign_id).to eq(another_campaign.id)
      expect(activity.activity_date).to eq(Time.zone.parse('2015-02-12 00:00:00'))
      expect(activity.company_user_id).to eq(another_user.id)
    end
  end


  describe "GET 'new'", search: true do
    it 'returns only the user/date if no fields have been aded to the activity type' do
      get :new, activity_type_id: activity_type.id, format: :json
      expect(json['data'].count).to eql 1
      expect(json['data'].first).to include(
        'name' => 'User/Date', 'value' => nil,
        'type' => 'FormField::UserDate', 'settings' => nil,
        'ordering' => 1, 'required' => nil, 'kpi_id' => nil)
    end

    it 'returns the fields have been aded to the activity type' do
      create(:form_field_text, fieldable: activity_type, ordering: 2)
      create(:form_field_number, fieldable: activity_type, ordering: 3)
      get :new, activity_type_id: activity_type.id, format: :json
      expect(json['data'].count).to eql 3

      expect(json['data'].map { |at|  at['type'] }).to eql [
        'FormField::UserDate', 'FormField::Text', 'FormField::Number']
    end
  end

  describe "GET 'show'", search: true do
    let(:activity) { create(:activity, activity_type: activity_type, company_user: company_user, activitable: event) }
    before { event.campaign.activity_types << activity_type }

    it 'retruns the activity info' do
      get :show, id: activity.id, format: :json
      expect(json['id']).to eql activity.id
      expect(json['company_user']['id']).to eql activity.company_user_id
      expect(json['company_user']['name']).to eql activity.company_user.full_name
    end

    it 'returns only the user/date if no fields have been aded to the activity type' do
      get :show, id: activity.id, format: :json
      expect(json['data'].count).to eql 1
      expect(json['data'].first).to include(
        'name' => 'User/Date', 'value' => [],
        'type' => 'FormField::UserDate', 'settings' => nil,
        'ordering' => 1, 'required' => nil, 'kpi_id' => nil)
    end

    it 'returns the fields have been aded to the activity type' do
      create(:form_field_text, fieldable: activity_type, ordering: 2)
      create(:form_field_number, fieldable: activity_type, ordering: 3)
      get :show, id: activity.id, format: :json
      expect(json['data'].count).to eql 3
      expect(json['data'].map { |at|  at['type'] }).to eql [
        'FormField::UserDate', 'FormField::Text', 'FormField::Number']
    end
  end
end
