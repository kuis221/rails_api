require 'spec_helper'

describe CampaignsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: campaign.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'items'" do
    it "returns http success" do
      get 'items'
      response.should be_success
    end
  end

  describe "GET 'new_date_range'" do
    it "returns http success" do
      date_range = FactoryGirl.create(:date_range, company: @company)
      other_date_range = FactoryGirl.create(:date_range, company_id: @company.id + 1)
      get 'new_date_range', id: campaign.to_param, format: :js
      response.should be_success
      response.should render_template(:new_date_range)
      assigns(:date_ranges).should == [date_range]
    end

    it "should not include the date ranges that are already assigned to the campaign" do
      date_range = FactoryGirl.create(:date_range, company: @company)
      assigned_range = FactoryGirl.create(:date_range, company: @company)
      campaign.date_ranges << assigned_range
      get 'new_date_range', id: campaign.to_param, format: :js
      response.should be_success
      response.should render_template(:new_date_range)
      assigns(:date_ranges).should == [date_range]
    end
  end

  describe "POST 'add_date_range'" do
    it "adds the date range to the campaign" do
      date_range = FactoryGirl.create(:date_range, company: @company)
      expect {
        post 'add_date_range', id: campaign.to_param, date_range_id: date_range.to_param, format: :js
      }.to change(campaign.date_ranges, :count).by(1)
      response.should be_success
      response.should render_template(:add_date_range)
      campaign.date_ranges.should == [date_range]
    end

    it "adds the date range to the campaign" do
      date_range = FactoryGirl.create(:date_range, company: @company)
      campaign.date_ranges << date_range
      campaign.reload.date_ranges.should == [date_range]
      expect {
        post 'add_date_range', id: campaign.to_param, date_range_id: date_range.to_param, format: :js
      }.to_not change(campaign.date_ranges, :count)
      response.should be_success
      response.should render_template(:add_date_range)
      campaign.reload.date_ranges.should == [date_range]
    end
  end

  describe "DELETE 'delete_date_range'" do
    it "should delete the date range from the campaign" do
      date_range = FactoryGirl.create(:date_range, company: @company)
      campaign.date_ranges << date_range
      expect {
        expect {
          delete 'delete_date_range', id: campaign.to_param, date_range_id: date_range.to_param, format: :js
        }.to_not change(DateRange, :count)
        response.should be_success
      }.to change(campaign.date_ranges, :count).by(-1)
    end
  end


  describe "GET 'new_day_part'" do
    it "returns http success" do
      day_part = FactoryGirl.create(:day_part, company: @company)
      other_date_range = FactoryGirl.create(:day_part, company_id: @company.id + 1)
      get 'new_day_part', id: campaign.to_param, format: :js
      response.should be_success
      response.should render_template(:new_day_part)
      assigns(:day_parts).should == [day_part]
    end

    it "should not include the day parts that are already assigned to the campaign" do
      day_part = FactoryGirl.create(:day_part, company: @company)
      assigned_part = FactoryGirl.create(:day_part, company: @company)
      campaign.day_parts << assigned_part
      get 'new_day_part', id: campaign.to_param, format: :js
      response.should be_success
      response.should render_template(:new_day_part)
      assigns(:day_parts).should == [day_part]
    end
  end

  describe "POST 'add_day_part'" do
    it "adds the day part to the campaign" do
      day_part = FactoryGirl.create(:day_part, company: @company)
      expect {
        post 'add_day_part', id: campaign.to_param, day_part_id: day_part.to_param, format: :js
      }.to change(campaign.day_parts, :count).by(1)
      response.should be_success
      response.should render_template(:add_day_part)
      campaign.day_parts.should == [day_part]
    end

    it 'doesn\'t add the day part if it already exists ' do
      day_part = FactoryGirl.create(:day_part, company: @company)
      campaign.day_parts << day_part
      campaign.reload.day_parts.should == [day_part]
      expect {
        post 'add_day_part', id: campaign.to_param, day_part_id: day_part.to_param, format: :js
      }.to_not change(campaign.day_parts, :count)
      response.should be_success
      response.should render_template(:add_day_part)
      campaign.reload.day_parts.should == [day_part]
    end
  end

  describe "DELETE 'delete_day_part'" do
    it "should delete the day part from the campaign" do
      day_part = FactoryGirl.create(:day_part, company: @company)
      campaign.day_parts << day_part
      expect {
        expect {
          delete 'delete_day_part', id: campaign.to_param, day_part_id: day_part.to_param, format: :js
        }.to_not change(DayPart, :count)
        response.should be_success
      }.to change(campaign.day_parts, :count).by(-1)
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should successfully create the new record" do
      portfolios = FactoryGirl.create_list(:brand_portfolio, 2, company: @company)
      FactoryGirl.create(:brand, name: 'Cacique')
      expect {
        expect {
          post 'create', campaign: {name: 'Test Campaign', description: 'Test Campaign description', brand_portfolio_ids: portfolios.map(&:id), brands_list: "Anchor Steam,Jack Daniels,Cacique"}, format: :js
        }.to change(Campaign, :count).by(1)
      }.to change(Brand, :count).by(2)
      campaign = Campaign.last
      campaign.name.should == 'Test Campaign'
      campaign.description.should == 'Test Campaign description'
      campaign.aasm_state.should == 'active'
      campaign.brand_portfolios.should =~ portfolios

      campaign.brands.all.map(&:name).should =~ ['Anchor Steam','Jack Daniels','Cacique']
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', campaign: {name: 'Test Campaign', description: 'Test Campaign description'}, format: :js
      }.should change(Campaign, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Campaign, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:campaign).errors.count > 0
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: campaign.id
      assigns(:campaign).should == campaign
      response.should render_template(:show)
    end
  end

  describe "GET 'deactivate'" do

    it "deactivates an active campaign" do
      campaign.update_attribute(:aasm_state, 'active')
      get 'deactivate', id: campaign.to_param, format: :js
      response.should be_success
      campaign.reload.active?.should be_false
    end
  end

  describe "GET 'activate'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: @company, aasm_state: 'inactive') }

    it "activates an inactive campaign" do
      campaign.active?.should be_false
      get 'activate', id: campaign.to_param, format: :js
      response.should be_success
      campaign.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    it "must update the campaign attributes" do
      t = FactoryGirl.create(:campaign, company: @company)
      put 'update', id: campaign.to_param, campaign: {name: 'Test Campaign', description: 'Test Campaign description'}
      assigns(:campaign).should == campaign
      response.should redirect_to(campaign_path(campaign))
      campaign.reload
      campaign.name.should == 'Test Campaign'
      campaign.description.should == 'Test Campaign description'
    end
  end


  describe "DELETE 'delete_member'" do
    it "should remove the team member from the campaign" do
      campaign.users << @company_user
      lambda{
        delete 'delete_member', id: campaign.id, member_id: @company_user.id, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should change(campaign.users, :count).by(-1)
    end

    it "should not raise error if the user doesn't belongs to the campaign" do
      delete 'delete_member', id: campaign.id, member_id: @user.id, format: :js
      campaign.reload
      response.should be_success
      assigns(:campaign).should == campaign
    end
  end

  describe "DELETE 'delete_member' with a team" do
    let(:team){ FactoryGirl.create(:team, company: @company) }
    it "should remove the team from the campaign" do
      campaign.teams << team
      lambda{
        delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should change(campaign.teams, :count).by(-1)
    end

    it "should not raise error if the team doesn't belongs to the campaign" do
      delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
      campaign.reload
      response.should be_success
      assigns(:campaign).should == campaign
    end
  end

  describe "GET 'new_member" do
    it 'should load all the company\'s users into @staff' do
      FactoryGirl.create(:user, company_id: @company.id+1)
      get 'new_member', id: campaign.id, format: :js
      response.should be_success
      assigns(:campaign).should == campaign
      assigns(:staff).should == [{'id' => @company_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user'}]
    end

    it 'should not load the users that are already assigned to the campaign' do
      another_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
      campaign.users << @company_user
      get 'new_member', id: campaign.id, format: :js
      response.should be_success
      assigns(:campaign).should == campaign
      assigns(:staff).should == [{'id' => another_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user'}]
    end

    it 'should load teams with active users' do
      team = FactoryGirl.create(:team, name:'ABC', description: 'A sample team', company_id: @company.id)
      team.users << @company_user
      get 'new_member', id: campaign.id, format: :js
      assigns(:assignable_teams).should == [team]
        assigns(:staff).should == [
          {'id' => team.id.to_s, 'name' => 'ABC', 'description' => 'A sample team', 'type' => 'team'},
          {'id' => @company_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user'}
        ]
    end

    it 'should not load teams without assignable users' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      campaign.users << @company_user
      get 'new_member', id: campaign.id, format: :js
      assigns(:assignable_teams).should == []
      assigns(:staff).should == []
    end
  end


  describe "POST 'add_members" do

    it 'should assign the user to the campaign' do
      lambda {
        post 'add_members', id: campaign.id, member_id: @company_user.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should change(campaign.users, :count).by(1)
      campaign.users.should == [@company_user]
    end

    it 'should assign all the team\'s users to the campaign' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      lambda {
        post 'add_members', id: campaign.id, team_id: team.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        assigns(:team_id).should == team.id.to_s
        campaign.reload
      }.should change(campaign.teams, :count).by(1)
      campaign.teams.should =~ [team]
    end

    it 'should not assign users to the campaign if they are already part of the campaign' do
      campaign.users << @company_user
      lambda {
        post 'add_members', id: campaign.id, member_id: @company_user.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should_not change(campaign.users, :count)
    end

    it 'should not assign teams to the campaign if they are already part of the campaign' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      campaign.teams << team
      lambda {
        post 'add_members', id: campaign.id, team_id: team.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should_not change(campaign.teams, :count)
    end
  end

  describe "GET 'tab'" do
    before do
      Kpi.create_global_kpis
    end
    it "loads the staff tab" do
      campaign.users << @company_user
      campaign.teams << FactoryGirl.create(:team, company: @company)
      get 'tab', id: campaign.id, tab: 'staff'
      assigns(:campaign).should == campaign
      response.should render_template(:staff)
      response.should render_template(:goalable_list)
    end

    it "loads the places tab" do
      campaign.places << FactoryGirl.create(:place, is_custom_place: true, reference: nil)
      campaign.areas << FactoryGirl.create(:area, company: @company)
      get 'tab', id: campaign.id, tab: 'places'
      assigns(:campaign).should == campaign
      response.should render_template(:places)
      response.should render_template(:goalable_list)
    end

    it "loads the date_ranges tab" do
      campaign.date_ranges << FactoryGirl.create(:date_range, company: @company)
      get 'tab', id: campaign.id, tab: 'date_ranges'
      assigns(:campaign).should == campaign
      response.should render_template(:date_ranges)
      response.should render_template(:goalable_list)
    end

    it "loads the day_parts tab" do
      campaign.day_parts << FactoryGirl.create(:day_part, company: @company)
      get 'tab', id: campaign.id, tab: 'day_parts'
      assigns(:campaign).should == campaign
      response.should render_template(:day_parts)
      response.should render_template(:goalable_list)
    end

    it "loads the documents tab" do
      campaign.documents << FactoryGirl.create(:attached_asset)
      get 'tab', id: campaign.id, tab: 'documents'
      assigns(:campaign).should == campaign
      response.should render_template(:documents)
    end
  end



  describe "POST 'update_post_event_form'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

    it "should save the form fields information" do
      Kpi.create_global_kpis
      expect {
        post 'update_post_event_form', id: campaign.id, fields: {
          '0' => {id: nil, name: 'Test 1', ordering: 1, kpi_id: Kpi.impressions, field_type: 'number', options: {capture_mechanism: 'integer'}},
          '1' => {id: nil, name: 'Test 2', ordering: 2, kpi_id: Kpi.interactions , field_type: 'number', options: {capture_mechanism: 'integer'}}
        }
      }.to change(CampaignFormField, :count).by(2)

      campaign.form_fields.count.should == 2

      response.should be_success
      response.body.should == 'OK'
    end


    it "should update the form fields information" do
      Kpi.create_global_kpis
      field = FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi: Kpi.impressions, ordering: 1, name: 'impressions', field_type: 'number', options: {capture_mechanism: 'integer'} )
      expect {
        post 'update_post_event_form', id: campaign.id, fields: {
          '0' => {id: field.id, name: '# Impressions', ordering: 1, kpi_id: Kpi.impressions, options: {capture_mechanism: 'number'}}
        }
      }.to_not change(CampaignFormField, :count)

      campaign.form_fields.count.should == 1

      field.reload.name.should == '# Impressions'

      response.should be_success
      response.body.should == 'OK'
    end

    it "should normalize brands" do
      Kpi.create_global_kpis
      brand = FactoryGirl.create(:brand, name: 'A brand')
      expect {
        post 'update_post_event_form', id: campaign.id, fields: {
          '0' => {id: nil, name: '# Impressions', ordering: 1, kpi_id: Kpi.impressions, options: {capture_mechanism: 'number', brands: ['A brand', 'Another brand']}}
        }
      }.to change(Brand, :count).by(1)

      campaign.form_fields.count.should == 1

      campaign.form_fields.first.options['brands'].count.should == 2
      campaign.form_fields.first.options['brands'].should include(brand.id)

      response.should be_success
      response.body.should == 'OK'
    end
  end

  describe "POST 'add_kpi'" do
    let(:kpi) { FactoryGirl.create(:kpi, company: @company, name: 'custom tes kpi', kpi_type: 'number', capture_mechanism: 'integer' ) }

    it "should associate the kpi to the campaign" do
      expect {
        post 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :json
      }.to change(CampaignFormField, :count).by(1)

      campaign.form_fields.count.should == 1
      field = campaign.form_fields.first
      field.kpi_id.should == kpi.id
      field.field_type.should == kpi.kpi_type
      field.name.should == kpi.name
      field.ordering.should == 1
      field.options[:capture_mechanism].should == 'integer'
    end

    it "should NOT associate the kpi to the campaign if the campaing already have it assgined" do
      FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi_id: kpi.id, ordering: 1, name: 'impressions', field_type: 'number', options: {capture_mechanism: 'integer'} )
      expect {
        post 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :json
      }.to_not change(CampaignFormField, :count)
    end

    it "should automatically assign a correct ordering for the new field" do
      FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi_id: 999, ordering: 1, name: 'impressions', field_type: 'number', options: {capture_mechanism: 'integer'} )
      expect {
        post 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :json
      }.to change(CampaignFormField, :count).by(1)

      campaign.form_fields.count.should == 2
      field = CampaignFormField.last
      field.ordering.should == 2
    end

    it "should update the form_field_id for any existing results for the kpi" do
      result = EventResult.create({form_field: FactoryGirl.create(:campaign_form_field, campaign: campaign), event: FactoryGirl.create(:event, campaign: campaign, company: @company), kpis_segment_id: nil, kpi_id: kpi.id}, without_protection: true)
      expect {
        post 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :json
      }.to change(CampaignFormField, :count).by(1)

      field = CampaignFormField.last
      result.reload.form_field_id.should == field.id
    end
  end

  describe "POST 'activity_type'" do
    let(:activity_type) { FactoryGirl.create(:activity_type, company: @company) }

    it "should associate the kpi to the campaign" do
      expect {
        post 'add_activity_type', id: campaign.id,activity_type_id: activity_type.id, format: :json
      }.to change(ActivityTypeCampaign, :count).by(1)
    end

    it "should NOT associate the activity_type to the campaign if the campaing already have it assgined" do
      expect {
        post 'remove_activity_type', id: campaign.id, activity_type_id: activity_type.id, format: :json
      }.to_not change(ActivityTypeCampaign, :count)
    end
  end

  describe "DELETE 'remove_activity_type'" do
    let(:activity_type) { FactoryGirl.create(:activity_type, company: @company) }
    it "should disassociate the activity_type from the campaign" do
      campaign.activity_types << activity_type
      expect {
        post 'remove_activity_type', id: campaign.id, activity_type_id: activity_type.id, format: :json
      }.to change(ActivityTypeCampaign, :count).by(-1)
      response.should be_success
    end
  end

  describe "DELETE 'remove_kpi'" do
    let(:kpi) { FactoryGirl.create(:kpi, company: @company, name: 'custom tes kpi', kpi_type: 'number', capture_mechanism: 'integer' ) }

    it "should disassociate the kpi from the campaign" do
      FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi_id: kpi.id, ordering: 1, name: 'impressions', field_type: 'number', options: {capture_mechanism: 'integer'} )
      expect {
        post 'remove_kpi', id: campaign.id, kpi_id: kpi.id, format: :json
      }.to change(CampaignFormField, :count).by(-1)
      response.should be_success
    end
  end

end
