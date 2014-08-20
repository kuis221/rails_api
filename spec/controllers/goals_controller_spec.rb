require 'rails_helper'

describe GoalsController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:kpi) {FactoryGirl.create(:kpi, company: @company)}
  let(:campaign) {FactoryGirl.create(:campaign, company: @company)}
  let(:company_user) {FactoryGirl.create(:company_user, company: @company)}
  let(:area) {FactoryGirl.create(:area, company: @company)}
  let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', company_user_id: company_user.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      xhr :post, 'create', company_user_id: company_user.to_param, goal: {value: '100', kpi_id: kpi.id}, format: :js
      expect(response).to be_success
      expect(response).to render_template('create')
    end

    it "should create a goal for the company user" do
      expect {
        xhr :post, 'create', company_user_id: company_user.to_param, goal: {value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :js
      }.to change(Goal, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      goal = Goal.last
      expect(goal.parent).to be_nil
      expect(goal.goalable).to eq(company_user)
      expect(goal.value).to eq(100)
      expect(goal.kpi_id).to eq(kpi.id)
      expect(goal.title).to eq('Goal Title')
      expect(goal.start_date).to eq(Time.zone.local(2012, 01, 31).to_date)
      expect(goal.due_date).to   eq(Time.zone.local(2013, 01, 31).to_date)
    end

    it "should create a goal for the company user in a given campaign" do
      expect {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :json
      }.to change(Goal, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      goal = Goal.last
      expect(goal.parent).to eq(campaign)
      expect(goal.goalable).to eq(company_user)
      expect(goal.value).to eq(100)
      expect(goal.kpi_id).to eq(kpi.id)
      expect(goal.title).to eq('Goal Title')
      expect(goal.start_date).to eq(Time.zone.local(2012, 01, 31).to_date)
      expect(goal.due_date).to   eq(Time.zone.local(2013, 01, 31).to_date)
    end

    it "should create an activity type goal for an area in a given campaign" do
      expect {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: area.id, goalable_type: 'Area', value: '55', activity_type_id: activity_type.id}, format: :json
      }.to change(Goal, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      goal = Goal.last
      expect(goal.parent).to eq(campaign)
      expect(goal.goalable).to eq(area)
      expect(goal.value).to eq(55)
      expect(goal.activity_type_id).to eq(activity_type.id)
    end

    it "should create an activity type goal for a company user in a given campaign" do
      expect {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '66', activity_type_id: activity_type.id}, format: :json
      }.to change(Goal, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      goal = Goal.last
      expect(goal.parent).to eq(campaign)
      expect(goal.goalable).to eq(company_user)
      expect(goal.value).to eq(66)
      expect(goal.activity_type_id).to eq(activity_type.id)
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', company_user_id: company_user.to_param, goal: {start_date: '99/99/9999'}, format: :js
      }.not_to change(Goal, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:goal).errors.count > 0
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      xhr :get, 'edit', company_user_id: company_user.to_param, id: goal.to_param, format: :js
      expect(response).to be_success
      expect(assigns(:company_user)).to eq(company_user)
      expect(assigns(:goal)).to eq(goal)
    end
  end

  describe "PUT 'update'" do
    it "should update the goal attributes for the company user" do
      goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      expect {
        xhr :put, 'update', company_user_id: company_user.to_param, id: goal.to_param, goal: {value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :js
      }.to_not change(Goal, :count)
      expect(response).to be_success
      expect(response).to render_template(:update)
      expect(response).not_to render_template('_form_dialog')

      goal.reload
      expect(goal.parent).to be_nil
      expect(goal.goalable).to eq(company_user)
      expect(goal.value).to eq(100)
      expect(goal.kpi_id).to eq(kpi.id)
      expect(goal.title).to eq('Goal Title')
      expect(goal.start_date).to eq(Time.zone.local(2012, 01, 31).to_date)
      expect(goal.due_date).to   eq(Time.zone.local(2013, 01, 31).to_date)
    end

    it "should update the goal value for the company user in a given campaign" do
      goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      expect {
        put 'update', id: goal.to_param, goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '110', kpi_id: kpi.id}, format: :json
      }.to_not change(Goal, :count)
      expect(response).to be_success
      expect(response).to render_template(:update)
      expect(response).not_to render_template('_form_dialog')

      goal.reload
      expect(goal.parent).to eq(campaign)
      expect(goal.goalable).to eq(company_user)
      expect(goal.value).to eq(110)
      expect(goal.kpi_id).to eq(kpi.id)
    end

    it "should update an activity type goal for an area in a given campaign" do
      area_goal = FactoryGirl.create(:goal, goalable: area, activity_type_id: activity_type.id)
      area_goal.save
      expect {
        post 'update', id: area_goal.to_param, goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: area.id, goalable_type: 'Area', value: '78', activity_type_id: activity_type.id}, format: :json
      }.to_not change(Goal, :count)
      expect(response).to be_success
      expect(response).to render_template(:update)
      expect(response).not_to render_template('_form_dialog')

      area_goal.reload
      expect(area_goal.parent).to eq(campaign)
      expect(area_goal.goalable).to eq(area)
      expect(area_goal.value).to eq(78)
      expect(area_goal.activity_type_id).to eq(activity_type.id)
    end

    it "should update an activity type goal for a company user in a given campaign" do
      user_goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      user_goal.save
      expect {
        post 'update', id: user_goal.to_param, goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '88', activity_type_id: activity_type.id}, format: :json
      }.to_not change(Goal, :count)
      expect(response).to be_success
      expect(response).to render_template(:update)
      expect(response).not_to render_template('_form_dialog')

      user_goal.reload
      expect(user_goal.parent).to eq(campaign)
      expect(user_goal.goalable).to eq(company_user)
      expect(user_goal.value).to eq(88)
      expect(user_goal.activity_type_id).to eq(activity_type.id)
    end
  end

end