require 'spec_helper'

describe ActivitiesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.company_users.first
    campaign.activity_types << activity_type
  end

  let(:activity_type) {FactoryGirl.create(:activity_type, company: @company)}
  let(:venue) {FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: @company)}
  let(:campaign) {FactoryGirl.create(:campaign, company: @company)}
  let(:activity) {FactoryGirl.create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign, company_user: @company_user)}

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', venue_id: venue.to_param, format: :js
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', venue_id: venue.to_param, format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', venue_id: venue.to_param, activity: {activity_type_id: activity_type.to_param, campaign_id: campaign.to_param, company_user_id: @company_user.to_param}, format: :js
      }.should change(Activity, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', venue_id: venue.to_param, format: :js
      }.should_not change(Activity, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:venue).errors.count > 0
    end

    it "should assign the correct venue id" do
      lambda {
        post 'create', venue_id: venue.to_param, activity: {activity_type_id: activity_type.to_param, campaign_id: campaign.to_param, company_user_id: @company_user.to_param, activity_date: '05/23/2020'}, format: :js
      }.should change(Activity, :count).by(1)
      assigns(:venue).should == venue
      assigns(:activity).activitable_id.should == venue.id
      assigns(:activity).activity_date.to_s.should == '05/23/2020 00:00:00'
    end

    it "should correctly save all the values for percentage field" do
      form_field = FactoryGirl.create(:form_field,
        fieldable: activity_type, type: 'FormField::Percentage',
        options: [FactoryGirl.create(:form_field_option, name: 'Option 1', ordering: 0), FactoryGirl.create(:form_field_option, name: 'Option 1', ordering: 1)])

      lambda {
        post 'create', venue_id: venue.to_param, activity: {
            activity_type_id: activity_type.to_param, campaign_id: campaign.to_param,
            company_user_id: @company_user.to_param, activity_date: '05/23/2020',
            results_attributes: {'0' =>
              {form_field_id: form_field.id, value: {
                form_field.options.first.id.to_s => '10',
                form_field.options.last.id.to_s => '90',
              }}
            }
          }, format: :js
      }.should change(Activity, :count).by(1)
      activity = Activity.last
      expect(activity.results.count).to eql 1
      result = activity.results.first
      expect(result.value).to eql({
        form_field.options.first.id.to_s => '10',
        form_field.options.last.id.to_s => '90'
      })
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', venue_id: venue.to_param, id: activity.to_param, format: :js
      response.should be_success
    end
  end

  describe "PUT 'update'" do
    let(:another_user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
    let(:another_campaign) {FactoryGirl.create(:campaign, company: @company)}

    it "must update the activity attributes" do
      another_campaign.activity_types << activity_type
      put 'update', venue_id: venue.to_param, id: activity.to_param, activity: {campaign_id: another_campaign.id, company_user_id: another_user.id, activity_date: '12/31/2013'}, format: :js
      assigns(:activity).should == activity
      response.should be_success
      activity.reload
      activity.campaign_id.should == another_campaign.id
      activity.activity_date.should == Time.zone.parse('2013-12-31 00:00:00')
      activity.company_user_id.should == another_user.id
    end
  end

  describe "GET 'deactivate'" do
    it "deactivates an active activity for a venue" do
      activity.update_attribute(:active, true)
      get 'deactivate', id: activity.to_param, format: :js
      response.should be_success
      activity.reload.active?.should be_falsey
    end

    it "activates an inactive activity for a venue" do
      activity.update_attribute(:active, false)
      get 'activate', id: activity.to_param, format: :js
      response.should be_success
      activity.reload.active?.should be_truthy
    end
  end
end