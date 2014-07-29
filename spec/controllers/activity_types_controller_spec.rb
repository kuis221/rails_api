require 'spec_helper'

describe ActivityTypesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'set_goal'" do
    let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }
    it "returns http success" do
      get 'set_goal', campaign_id: campaign.to_param, activity_type_id: activity_type.to_param, format: :js
      assigns(:campaign).should == campaign
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }
    it "returns http success" do
      get 'edit', id: activity_type.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "PUT 'update'" do
    let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }
    it "must update the activity type attributes" do
      activity_type.save
      expect {
        expect {
          put 'update', id: activity_type.to_param,
              activity_type: {goals_attributes:
                [{goalable_id: campaign.to_param, goalable_type: 'Campaign', activity_type_id: activity_type.to_param, value: 23}]
              }, format: :js
        }.to change(Goal, :count).by(1)
      }.to_not change(ActivityType, :count)
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      campaign.goals.for_activity_types([activity_type]).first.value.should == 23
      assigns(:activity_type).should == activity_type
    end

    it "must allow create form fields" do
      activity_type.save
      expect {
        expect {
          put 'update', id: activity_type.to_param,
              activity_type: {form_fields_attributes:
                {id: nil, field_type: 'FormField::Text', name: 'Test Field', ordering: 0, required: true}
              }, format: :json
        }.to change(FormField, :count).by(1)
      }.to_not change(ActivityType, :count)
      field = FormField.last
      expect(field.name).to eql 'Test Field'
      expect(field.ordering).to eql 0
      expect(field.required).to be_truthy
      expect(field.type).to eql 'FormField::Text'
    end

    it "must allow update form fields" do
      activity_type.save
      field = FactoryGirl.create(:form_field, fieldable: activity_type,
        type: 'FormField::Text', name: 'Test Field',
        ordering: 0, required: true )
      expect {
        expect {
          put 'update', id: activity_type.to_param,
              activity_type: {form_fields_attributes:
                {id: field.id, field_type: 'FormField::Text', name: 'New name', ordering: 0, required: false}
              }, format: :json
        }.to_not change(FormField, :count)
      }.to_not change(ActivityType, :count)
      field = FormField.last
      expect(field.name).to eql 'New name'
      expect(field.ordering).to eql 0
      expect(field.required).to be_falsey
      expect(field.type).to eql 'FormField::Text'
    end

    it "must allow create form fields with nested options" do
      activity_type.save
      expect {
        expect {
          expect {
            put 'update', id: activity_type.to_param,
                activity_type: {form_fields_attributes:
                  {id: nil, field_type: 'FormField::Radio', name: 'Radio Field', ordering: 0, required: true,
                    options_attributes: [{name: 'One Option', ordering: 0}, {name: 'Other Option', ordering: 1}] }
                }, format: :json
          }.to change(FormField, :count).by(1)
        }.to change(FormFieldOption, :count).by(2)
      }.to_not change(ActivityType, :count)
      field = FormField.last
      expect(field.options.map(&:name)).to eql ['One Option', 'Other Option']
    end

    it "must allow remove form fields" do
      activity_type.save
      field = FactoryGirl.create(:form_field, fieldable: activity_type,
        type: 'FormField::Text', name: 'Test Field',
        ordering: 0, required: true )
      expect {
        expect {
          put 'update', id: activity_type.to_param,
              activity_type: {form_fields_attributes:
                {id: field.id, _destroy: true}
              }, format: :json
        }.to change(FormField, :count).by(-1)
      }.to_not change(ActivityType, :count)
    end
  end

  describe "GET 'items'" do
    it "responds to .json format" do
      get 'items'
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
    end
  end

    describe "POST 'create'" do
    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', activity_type: {name: 'Activity Type test', description: 'Activity Type description'}, format: :js
      }.should change(ActivityType, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      type = ActivityType.last
      type.name.should == 'Activity Type test'
      type.description.should == 'Activity Type description'
      type.active.should be_truthy
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(ActivityType, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:activity_type).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }

    it "deactivates an active brand_portfolio" do
      activity_type.update_attribute(:active, true)
      get 'deactivate', id: activity_type.to_param, format: :js
      response.should be_success
      activity_type.reload.active?.should be_falsey
    end

    it "activates an inactive brand_portfolio" do
      activity_type.update_attribute(:active, false)
      get 'activate', id: activity_type.to_param, format: :js
      response.should be_success
      activity_type.reload.active?.should be_truthy
    end
  end
end