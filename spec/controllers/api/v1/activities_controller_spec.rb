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
    it 'returns only the user/date if no fields have been added to the activity type' do
      get :new, activity_type_id: activity_type.id, format: :json
      expect(json['data'].count).to eql 1
      expect(json['data'].first).to include(
        'name' => 'User/Date', 'value' => nil,
        'type' => 'FormField::UserDate', 'ordering' => 1, 'required' => false)
    end

    it 'returns the fields have been aded to the activity type', show_in_doc: true do
      create(:form_field_text, fieldable: activity_type, ordering: 2)
      create(:form_field_attachment, fieldable: activity_type, ordering: 3)
      create(:form_field_checkbox, fieldable: activity_type, ordering: 4,
                                   options: [
                                     create(:form_field_option, name: 'Checkbox A'),
                                     create(:form_field_option, name: 'Checkbox B'),
                                     create(:form_field_option, name: 'Checkbox C')
                                   ])
      create(:form_field_brand, fieldable: activity_type, ordering: 5)
      create(:form_field_currency, fieldable: activity_type, ordering: 6)
      create(:form_field_date, fieldable: activity_type, ordering: 7)
      create(:form_field_dropdown, fieldable: activity_type, ordering: 8,
                                   options: [
                                     create(:form_field_option, name: 'Option A'),
                                     create(:form_field_option, name: 'Option B'),
                                     create(:form_field_option, name: 'Option C')
                                   ])
      create(:form_field_likert_scale, fieldable: activity_type, ordering: 9,
                                       options: [
                                         create(:form_field_option, name: 'Option 1'),
                                         create(:form_field_option, name: 'Option 2'),
                                         create(:form_field_option, name: 'Option 3')
                                       ],
                                       statements: [
                                         create(:form_field_option, name: 'Statement A'),
                                         create(:form_field_option, name: 'Statement B'),
                                         create(:form_field_option, name: 'Statement C')
                                       ])
      create(:form_field_marque, fieldable: activity_type, ordering: 10)
      create(:form_field_number, fieldable: activity_type, ordering: 11)
      create(:form_field_percentage, fieldable: activity_type, ordering: 12)
      create(:form_field_photo, fieldable: activity_type, ordering: 13)
      create(:form_field_place, fieldable: activity_type, ordering: 14)

      create(:form_field_radio, fieldable: activity_type, ordering: 15,
                                options: [
                                  create(:form_field_option, name: 'Option A'),
                                  create(:form_field_option, name: 'Option B'),
                                  create(:form_field_option, name: 'Option C')
                                ])
      create(:form_field_section, fieldable: activity_type, ordering: 16)
      create(:form_field_calculation, fieldable: activity_type, ordering: 17)
      create(:form_field_text_area, fieldable: activity_type, ordering: 18)
      create(:form_field_time, fieldable: activity_type, ordering: 19)

      get :new, activity_type_id: activity_type.id, format: :json
      expect(json['data'].count).to eql 19
      expect(json['data'].map { |at|  at['type'] }).to eql [
        'FormField::UserDate', 'FormField::Text', 'FormField::Attachment', 'FormField::Checkbox',
        'FormField::Brand', 'FormField::Currency', 'FormField::Date', 'FormField::Dropdown',
        'FormField::LikertScale', 'FormField::Marque', 'FormField::Number', 'FormField::Percentage',
        'FormField::Photo', 'FormField::Place', 'FormField::Radio', 'FormField::Section',
        'FormField::Calculation', 'FormField::TextArea', 'FormField::Time']
    end
  end

  describe "GET 'show'", search: true do
    let(:activity) { create(:activity, activity_type: activity_type, company_user: company_user, activitable: event) }
    before { event.campaign.activity_types << activity_type }

    it 'returns the activity info' do
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
        'type' => 'FormField::UserDate', 'ordering' => 1, 'required' => false)
    end

    it 'returns the fields have been aded to the activity type', :show_in_doc do
      field = create(:form_field_text, fieldable: activity_type, ordering: 2)
      activity.results_for([field]).first.value = 'lorem ipsum dolor sit amet'
      create(:form_field_attachment, fieldable: activity_type, ordering: 3)
      field = create(:form_field_checkbox, fieldable: activity_type, ordering: 4,
                                           options: [
                                             opt1 = create(:form_field_option, name: 'Checkbox A'),
                                             opt2 = create(:form_field_option, name: 'Checkbox B'),
                                             create(:form_field_option, name: 'Checkbox C')
                                           ])
      activity.results_for([field]).first.value = [opt1.id, opt2.id]
      create(:form_field_brand, fieldable: activity_type, ordering: 5)
      create(:form_field_currency, fieldable: activity_type, ordering: 6)
      create(:form_field_date, fieldable: activity_type, ordering: 7)
      create(:form_field_dropdown, fieldable: activity_type, ordering: 8,
                                   options: [
                                     create(:form_field_option, name: 'Option A'),
                                     create(:form_field_option, name: 'Option B'),
                                     create(:form_field_option, name: 'Option C')
                                   ])
      create(:form_field_likert_scale, fieldable: activity_type, ordering: 9,
                                       options: [
                                         create(:form_field_option, name: 'Option 1'),
                                         create(:form_field_option, name: 'Option 2'),
                                         create(:form_field_option, name: 'Option 3')
                                       ],
                                       statements: [
                                         create(:form_field_option, name: 'Statement A'),
                                         create(:form_field_option, name: 'Statement B'),
                                         create(:form_field_option, name: 'Statement C')
                                       ])
      create(:form_field_marque, fieldable: activity_type, ordering: 10)
      create(:form_field_number, fieldable: activity_type, ordering: 11)
      create(:form_field_percentage, fieldable: activity_type, ordering: 12)
      create(:form_field_photo, fieldable: activity_type, ordering: 13)
      place = create(:place, name: 'Parales', formatted_address: 'Parales, Curridabat')
      field = create(:form_field_place, fieldable: activity_type, ordering: 14)
      activity.results_for([field]).first.value = place.id

      create(:form_field_radio, fieldable: activity_type, ordering: 15,
                                options: [
                                  create(:form_field_option, name: 'Option A'),
                                  create(:form_field_option, name: 'Option B'),
                                  create(:form_field_option, name: 'Option C')
                                ])
      create(:form_field_section, fieldable: activity_type, ordering: 16)
      create(:form_field_calculation, fieldable: activity_type, ordering: 17)
      create(:form_field_text_area, fieldable: activity_type, ordering: 18)
      create(:form_field_time, fieldable: activity_type, ordering: 19)
      activity.save
      get :show, id: activity.id, format: :json
      expect(json['data'].count).to eql 19
      expect(json['data'].map { |at|  at['type'] }).to eql [
        'FormField::UserDate', 'FormField::Text', 'FormField::Attachment', 'FormField::Checkbox',
        'FormField::Brand', 'FormField::Currency', 'FormField::Date', 'FormField::Dropdown',
        'FormField::LikertScale', 'FormField::Marque', 'FormField::Number', 'FormField::Percentage',
        'FormField::Photo', 'FormField::Place', 'FormField::Radio', 'FormField::Section',
        'FormField::Calculation', 'FormField::TextArea', 'FormField::Time']
    end
  end
end
