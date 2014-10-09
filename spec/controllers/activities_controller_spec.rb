require 'rails_helper'

describe ActivitiesController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.company_users.first
    campaign.activity_types << activity_type
  end

  let(:activity_type) { create(:activity_type, company: @company) }
  let(:venue) { create(:venue, place: create(:place), company: @company) }
  let(:campaign) { create(:campaign, company: @company) }
  let(:activity) { create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign, company_user: @company_user) }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', venue_id: venue.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', venue_id: venue.to_param, format: :js
      expect(response).to be_success
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', venue_id: venue.to_param, activity: { activity_type_id: activity_type.to_param, campaign_id: campaign.to_param, company_user_id: @company_user.to_param }, format: :js
      end.to change(Activity, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', venue_id: venue.to_param, format: :js
      end.not_to change(Activity, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:venue).errors.count > 0
    end

    it 'should assign the correct venue id' do
      expect do
        xhr :post, 'create', venue_id: venue.to_param, activity: { activity_type_id: activity_type.to_param, campaign_id: campaign.to_param, company_user_id: @company_user.to_param, activity_date: '05/23/2020' }, format: :js
      end.to change(Activity, :count).by(1)
      expect(assigns(:venue)).to eq(venue)
      expect(assigns(:activity).activitable_id).to eq(venue.id)
      expect(assigns(:activity).activity_date.to_s).to eq('05/23/2020 00:00:00')
    end

    it 'should correctly save all the values for percentage field' do
      form_field = create(:form_field,
                                      fieldable: activity_type, type: 'FormField::Percentage',
                                      options: [create(:form_field_option, name: 'Option 1', ordering: 0), create(:form_field_option, name: 'Option 1', ordering: 1)])

      expect do
        post 'create', venue_id: venue.to_param, activity: {
          activity_type_id: activity_type.to_param, campaign_id: campaign.to_param,
            company_user_id: @company_user.to_param, activity_date: '05/23/2020',
            results_attributes: { '0' =>
              { form_field_id: form_field.id, value: {
                form_field.options.first.id.to_s => '10',
                form_field.options.last.id.to_s => '90'
              } }
            }
        }, format: :js
      end.to change(Activity, :count).by(1)
      activity = Activity.last
      expect(activity.results.count).to eql 1
      result = activity.results.first
      expect(result.value).to eql(
          form_field.options.first.id.to_s => '10',
          form_field.options.last.id.to_s => '90')
    end
  end

  describe "GET 'edit'" do
    it 'returns http success' do
      xhr :get, 'edit', venue_id: venue.to_param, id: activity.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "PUT 'update'" do
    let(:another_user) { create(:company_user, user: create(:user), company_id: @company.id) }
    let(:another_campaign) { create(:campaign, company: @company) }

    it 'must update the activity attributes' do
      another_campaign.activity_types << activity_type
      xhr :put, 'update', venue_id: venue.to_param, id: activity.to_param, activity: { campaign_id: another_campaign.id, company_user_id: another_user.id, activity_date: '12/31/2013' }, format: :js
      expect(assigns(:activity)).to eq(activity)
      expect(response).to be_success
      activity.reload
      expect(activity.campaign_id).to eq(another_campaign.id)
      expect(activity.activity_date).to eq(Time.zone.parse('2013-12-31 00:00:00'))
      expect(activity.company_user_id).to eq(another_user.id)
    end
  end

  describe "GET 'deactivate'" do
    it 'deactivates an active activity for a venue' do
      activity.update_attribute(:active, true)
      xhr :get, 'deactivate', id: activity.to_param, format: :js
      expect(response).to be_success
      expect(activity.reload.active?).to be_falsey
    end

    it 'activates an inactive activity for a venue' do
      activity.update_attribute(:active, false)
      xhr :get, 'activate', id: activity.to_param, format: :js
      expect(response).to be_success
      expect(activity.reload.active?).to be_truthy
    end
  end
end
