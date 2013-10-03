require 'spec_helper'

describe GoalsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:kpi) {FactoryGirl.create(:kpi, company: @company)}
  let(:goal) {FactoryGirl.create(:goal, goalable: company_user)}
  let(:campaign) {FactoryGirl.create(:campaign, company: @company)}
  let(:company_user) {FactoryGirl.create(:company_user, company: @company)}

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', company_user_id: company_user.to_param, goal: {value: '100', kpi_id: kpi.id}, format: :js
      response.should be_success
      response.should render_template('create')
    end

    it "should create a goal for the company user" do
      lambda {
        post 'create', company_user_id: company_user.to_param, goal: {value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :js
      }.should change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      goal = Goal.last
      goal.parent.should be_nil
      goal.goalable.should == company_user
      goal.value.should == 100
      goal.kpi_id.should == kpi.id
      goal.title.should == 'Goal Title'
      goal.start_date.should == Time.zone.local(2012, 01, 31).to_date
      goal.due_date.should   == Time.zone.local(2013, 01, 31).to_date
    end

    it "should create a goal for the company user in a given campaign" do
      lambda {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :json
      }.should change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      goal = Goal.last
      goal.parent.should == campaign
      goal.goalable.should == company_user
      goal.value.should == 100
      goal.kpi_id.should == kpi.id
      goal.title.should == 'Goal Title'
      goal.start_date.should == Time.zone.local(2012, 01, 31).to_date
      goal.due_date.should   == Time.zone.local(2013, 01, 31).to_date
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', company_user_id: company_user.to_param, goal: {start_date: '99/99/9999'}, format: :js
      }.should_not change(Goal, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:goal).errors.count > 0
    end
  end

  describe "PUT 'update'" do
    it "should update the goal attributes" do
      goal.save
      expect {
        put 'update', company_user_id: company_user.to_param, id: goal.to_param, goal: {value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :js
      }.to_not change(Goal, :count)
      response.should be_success
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      goal.reload
      goal.parent.should be_nil
      goal.goalable.should == company_user
      goal.value.should == 100
      goal.kpi_id.should == kpi.id
      goal.title.should == 'Goal Title'
      goal.start_date.should == Time.zone.local(2012, 01, 31).to_date
      goal.due_date.should   == Time.zone.local(2013, 01, 31).to_date
    end
  end

end