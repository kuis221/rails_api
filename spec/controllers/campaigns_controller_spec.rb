require 'rails_helper'

describe CampaignsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:campaign) { create(:campaign, company: @company) }

  describe "GET 'edit'" do
    it 'returns http success' do
      xhr :get, 'edit', id: campaign.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'returns http success' do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "GET 'new_date_range'" do
    it 'returns http success' do
      date_range = create(:date_range, company: @company)
      other_date_range = create(:date_range, company_id: @company.id + 1)
      xhr :get, 'new_date_range', id: campaign.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template(:new_date_range)
      expect(assigns(:date_ranges)).to eq([date_range])
    end

    it 'should not include the date ranges that are already assigned to the campaign' do
      date_range = create(:date_range, company: @company)
      assigned_range = create(:date_range, company: @company)
      campaign.date_ranges << assigned_range
      xhr :get, 'new_date_range', id: campaign.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template(:new_date_range)
      expect(assigns(:date_ranges)).to eq([date_range])
    end
  end

  describe "POST 'add_date_range'" do
    it 'adds the date range to the campaign' do
      date_range = create(:date_range, company: @company)
      expect do
        xhr :post, 'add_date_range', id: campaign.to_param, date_range_id: date_range.to_param, format: :js
      end.to change(campaign.date_ranges, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:add_date_range)
      expect(campaign.date_ranges).to eq([date_range])
    end

    it 'adds the date range to the campaign' do
      date_range = create(:date_range, company: @company)
      campaign.date_ranges << date_range
      expect(campaign.reload.date_ranges).to eq([date_range])
      expect do
        xhr :post, 'add_date_range', id: campaign.to_param, date_range_id: date_range.to_param, format: :js
      end.to_not change(campaign.date_ranges, :count)
      expect(response).to be_success
      expect(response).to render_template(:add_date_range)
      expect(campaign.reload.date_ranges).to eq([date_range])
    end
  end

  describe "DELETE 'delete_date_range'" do
    it 'should delete the date range from the campaign' do
      date_range = create(:date_range, company: @company)
      campaign.date_ranges << date_range

      create(:goal, goalable: date_range, parent: campaign, kpi: create(:kpi))
      create(:goal, goalable: date_range, parent: campaign, kpi: create(:kpi))

      # this should not be deleted
      goal = create(:goal, goalable: date_range, kpi: create(:kpi))

      expect do
        expect do
          expect do
            delete 'delete_date_range', id: campaign.to_param, date_range_id: date_range.to_param, format: :js
          end.to_not change(DateRange, :count)
          expect(response).to be_success
        end.to change(campaign.date_ranges, :count).by(-1)
      end.to change(Goal, :count).by(-2)
      expect(goal.reload).to be_truthy
    end
  end

  describe "GET 'new_day_part'" do
    it 'returns http success' do
      day_part = create(:day_part, company: @company)
      other_date_range = create(:day_part, company_id: @company.id + 1)
      xhr :get, 'new_day_part', id: campaign.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template(:new_day_part)
      expect(assigns(:day_parts)).to eq([day_part])
    end

    it 'should not include the day parts that are already assigned to the campaign' do
      day_part = create(:day_part, company: @company)
      assigned_part = create(:day_part, company: @company)
      campaign.day_parts << assigned_part
      xhr :get, 'new_day_part', id: campaign.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template(:new_day_part)
      expect(assigns(:day_parts)).to eq([day_part])
    end
  end

  describe "POST 'add_day_part'" do
    it 'adds the day part to the campaign' do
      day_part = create(:day_part, company: @company)
      expect do
        xhr :post, 'add_day_part', id: campaign.to_param, day_part_id: day_part.to_param, format: :js
      end.to change(campaign.day_parts, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:add_day_part)
      expect(campaign.day_parts).to eq([day_part])
    end

    it 'doesn\'t add the day part if it already exists ' do
      day_part = create(:day_part, company: @company)
      campaign.day_parts << day_part
      expect(campaign.reload.day_parts).to eq([day_part])
      expect do
        xhr :post, 'add_day_part', id: campaign.to_param, day_part_id: day_part.to_param, format: :js
      end.to_not change(campaign.day_parts, :count)
      expect(response).to be_success
      expect(response).to render_template(:add_day_part)
      expect(campaign.reload.day_parts).to eq([day_part])
    end
  end

  describe "DELETE 'delete_day_part'" do
    it 'should delete the day part from the campaign' do
      day_part = create(:day_part, company: @company)
      campaign.day_parts << day_part

      create(:goal, goalable: day_part, parent: campaign, kpi: create(:kpi))
      create(:goal, goalable: day_part, parent: campaign, kpi: create(:kpi))

      # this should not be deleted
      goal = create(:goal, goalable: day_part, kpi: create(:kpi))

      expect do
        expect do
          expect do
            delete 'delete_day_part', id: campaign.to_param, day_part_id: day_part.to_param, format: :js
          end.to_not change(DayPart, :count)
          expect(response).to be_success
        end.to change(campaign.day_parts, :count).by(-1)
      end.to change(Goal, :count).by(-2)
      expect(goal.reload).to be_truthy
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', format: :js
      expect(response).to be_success
    end

    it 'should successfully create the new record' do
      portfolios = create_list(:brand_portfolio, 2, company: @company)
      create(:brand, name: 'Cacique', company: @company)
      expect do
        expect do
          xhr :post, 'create', campaign: { name: 'Test Campaign', description: 'Test Campaign description', brand_portfolio_ids: portfolios.map(&:id), brands_list: 'Anchor Steam,Jack Daniels,Cacique' }, format: :js
        end.to change(Campaign, :count).by(1)
      end.to change(Brand, :count).by(2)
      campaign = Campaign.last
      expect(campaign.name).to eq('Test Campaign')
      expect(campaign.description).to eq('Test Campaign description')
      expect(campaign.aasm_state).to eq('active')
      expect(campaign.brand_portfolios).to match_array(portfolios)

      expect(campaign.brands.all.map(&:name)).to match_array(['Anchor Steam', 'Jack Daniels', 'Cacique'])
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', campaign: { name: 'Test Campaign', description: 'Test Campaign description' }, format: :js
      end.to change(Campaign, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(Campaign, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:campaign).errors.count > 0
    end
  end

  describe "GET 'show'" do
    it 'assigns the loads the correct objects and templates' do
      get 'show', id: campaign.id
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to render_template(:show)
    end
  end

  describe "GET 'deactivate'" do

    it 'deactivates an active campaign' do
      campaign.update_attribute(:aasm_state, 'active')
      xhr :get, 'deactivate', id: campaign.to_param, format: :js
      expect(response).to be_success
      expect(campaign.reload.active?).to be_falsey
    end
  end

  describe "GET 'activate'" do
    let(:campaign) { create(:campaign, company: @company, aasm_state: 'inactive') }

    it 'activates an inactive campaign' do
      expect(campaign.active?).to be_falsey
      xhr :get, 'activate', id: campaign.to_param, format: :js
      expect(response).to be_success
      expect(campaign.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    it 'must update the campaign attributes' do
      t = create(:campaign, company: @company)
      put 'update', id: campaign.to_param, campaign: { name: 'Test Campaign', description: 'Test Campaign description' }
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to redirect_to(campaign_path(campaign))
      campaign.reload
      expect(campaign.name).to eq('Test Campaign')
      expect(campaign.description).to eq('Test Campaign description')
    end

    it 'must allow create form fields' do
      campaign.save
      expect do
        expect do
          put 'update', id: campaign.to_param,
              campaign: { form_fields_attributes:
                { id: nil, field_type: 'FormField::Text', name: 'Test Field', ordering: 0, required: true }
              }, format: :json
        end.to change(FormField, :count).by(1)
      end.to_not change(ActivityType, :count)
      field = FormField.last
      expect(field.name).to eql 'Test Field'
      expect(field.ordering).to eql 0
      expect(field.required).to be_truthy
      expect(field.type).to eql 'FormField::Text'
    end

    it 'must allow update form fields' do
      campaign.save
      field = create(:form_field, fieldable: campaign,
        type: 'FormField::Text', name: 'Test Field',
        ordering: 0, required: true)
      expect do
        expect do
          put 'update', id: campaign.to_param,
              campaign: { form_fields_attributes:
                { id: field.id, field_type: 'FormField::Text',
                  name: 'New name', ordering: 0, required: false,
                  settings: { description: 'some example', range_min: '100', range_max: '200', range_format: 'characters' } }
              }, format: :json
        end.to_not change(FormField, :count)
      end.to_not change(Campaign, :count)
      field = FormField.last
      expect(field.name).to eql 'New name'
      expect(field.ordering).to eql 0
      expect(field.required).to be_falsey
      expect(field.settings['description']).to eql 'some example'
      expect(field.settings['range_min']).to eql '100'
      expect(field.settings['range_max']).to eql '200'
      expect(field.settings['range_format']).to eql 'characters'
      expect(field.type).to eql 'FormField::Text'
    end

    it 'must allow create form fields with nested options' do
      campaign.save
      expect do
        expect do
          expect do
            put 'update', id: campaign.to_param,
                campaign: { form_fields_attributes:
                  { id: nil, field_type: 'FormField::Radio', name: 'Radio Field', ordering: 0, required: true,
                    options_attributes: [{ name: 'One Option', ordering: 0 }, { name: 'Other Option', ordering: 1 }] }
                }, format: :json
          end.to change(FormField, :count).by(1)
        end.to change(FormFieldOption, :count).by(2)
      end.to_not change(Campaign, :count)
      field = FormField.last
      expect(field.options.map(&:name)).to eql ['One Option', 'Other Option']
    end

    it 'must allow remove form fields' do
      campaign.save
      field = create(:form_field, fieldable: campaign,
        type: 'FormField::Text', name: 'Test Field',
        ordering: 0, required: true)
      expect do
        expect do
          put 'update', id: campaign.to_param,
              campaign: { form_fields_attributes:
                { id: field.id, _destroy: true }
              }, format: :json
        end.to change(FormField, :count).by(-1)
      end.to_not change(Campaign, :count)
    end

    it 'should normalize survey brands' do
      Kpi.create_global_kpis
      brand = create(:brand, company: @company, name: 'A brand')
      expect do
        put 'update', id: campaign.to_param, campaign: {
          modules: { 'surveys' => { 'name' => 'Surveys' } },
          survey_brand_ids: ['A brand', 'Another brand']
        }, format: :json
      end.to change(Brand, :count).by(1)

      expect(campaign.reload.enabled_modules.count).to eql 1
      expect(campaign.survey_brand_ids.count).to eql 2
      expect(campaign.survey_brand_ids).to include(brand.id)

      expect(response).to be_success
    end

    it 'should accept empty modules' do
      Kpi.create_global_kpis
      brand = create(:brand, company: @company, name: 'A brand')
      campaign.update_attribute :modules, 'surveys' => {}
      put 'update', id: campaign.to_param, campaign: {
        modules: { 'empty' => true }
      }, format: :json

      expect(campaign.reload.enabled_modules.count).to eql 0
      expect(response).to be_success
    end
  end

  describe "DELETE 'delete_member'" do
    it 'should remove the team member from the campaign and remove any goal' do
      create(:goal, goalable: @company_user, parent: campaign, kpi: create(:kpi))
      create(:goal, goalable: @company_user, parent: campaign, kpi: create(:kpi))

      # this should not be deleted
      goal = create(:goal, goalable: @company_user, kpi: create(:kpi))

      campaign.users << @company_user
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{@company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{@company_user.id}").at_least(:once)
      expect do
        expect do
          delete 'delete_member', id: campaign.id, member_id: @company_user.id, format: :js
          expect(response).to be_success
          expect(assigns(:campaign)).to eq(campaign)
          campaign.reload
        end.to change(campaign.users, :count).by(-1)
      end.to change(Goal, :count).by(-2)
      expect(goal.reload).to be_truthy
    end

    it 'should remove the team  from the campaign and remove any goal' do
      team = create(:team, company: @company)
      create(:goal, goalable: team, parent: campaign, kpi: create(:kpi))
      create(:goal, goalable: team, parent: campaign, kpi: create(:kpi))

      # this should not be deleted
      goal = create(:goal, goalable: team, kpi: create(:kpi))

      campaign.teams << team
      expect do
        expect do
          delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
          expect(response).to be_success
          expect(assigns(:campaign)).to eq(campaign)
          campaign.reload
        end.to change(campaign.teams, :count).by(-1)
      end.to change(Goal, :count).by(-2)
      expect(goal.reload).to be_truthy
    end

    it "should not raise error if the user doesn't belongs to the campaign" do
      delete 'delete_member', id: campaign.id, member_id: @user.id, format: :js
      campaign.reload
      expect(response).to be_success
      expect(assigns(:campaign)).to eq(campaign)
    end
  end

  describe "DELETE 'delete_member' with a team" do
    let(:team) { create(:team, company: @company) }
    it 'should remove the team from the campaign' do
      campaign.teams << team
      expect do
        delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
        expect(response).to be_success
        expect(assigns(:campaign)).to eq(campaign)
        campaign.reload
      end.to change(campaign.teams, :count).by(-1)
    end

    it "should not raise error if the team doesn't belongs to the campaign" do
      delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
      campaign.reload
      expect(response).to be_success
      expect(assigns(:campaign)).to eq(campaign)
    end
  end

  describe "GET 'new_member" do
    it 'should load all the company\'s users into @staff' do
      create(:user, company_id: @company.id + 1)
      xhr :get, 'new_member', id: campaign.id, format: :js
      expect(response).to be_success
      expect(assigns(:campaign)).to eq(campaign)
      expect(assigns(:staff).to_a).to eq([{ 'id' => @company_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user' }])
    end

    it 'should not load the users that are already assigned to the campaign' do
      another_user = create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
      campaign.users << @company_user
      xhr :get, 'new_member', id: campaign.id, format: :js
      expect(response).to be_success
      expect(assigns(:campaign)).to eq(campaign)
      expect(assigns(:staff).to_a).to eq([{ 'id' => another_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user' }])
    end

    it 'should load teams with active users' do
      team = create(:team, name: 'ABC', description: 'A sample team', company_id: @company.id)
      team.users << @company_user
      xhr :get, 'new_member', id: campaign.id, format: :js
      expect(assigns(:assignable_teams)).to eq([team])
      expect(assigns(:staff).to_a).to eq([
        { 'id' => team.id.to_s, 'name' => 'ABC', 'description' => 'A sample team', 'type' => 'team' },
        { 'id' => @company_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user' }
      ])
    end

    it 'should not load teams without assignable users' do
      team = create(:team, company_id: @company.id)
      campaign.users << @company_user
      xhr :get, 'new_member', id: campaign.id, format: :js
      expect(assigns(:assignable_teams)).to eq([])
      expect(assigns(:staff).to_a).to eq([])
    end
  end

  describe "POST 'add_members" do
    it 'should assign the user to the campaign' do
      with_resque do
        @company_user.update_attributes(
          notifications_settings: %w(new_campaign_sms new_campaign_email),
          user_attributes: { phone_number_verified: true }
        )
        message = "You have a new campaign http://localhost:5100/campaigns/#{campaign.id}"
        expect(UserMailer).to receive(:notification).with(@company_user.id, 'New Campaign', message).and_return(double(deliver: true))
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{@company_user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{@company_user.id}").at_least(:once)
        expect do
          xhr :post, 'add_members', id: campaign.id, member_id: @company_user.to_param, format: :js
          expect(response).to be_success
          expect(assigns(:campaign)).to eq(campaign)
          campaign.reload
        end.to change(campaign.users, :count).by(1)
        expect(campaign.users).to eq([@company_user])
        open_last_text_message_for @user.phone_number
        expect(current_text_message).to have_body message
      end
    end

    it 'should assign all the team\'s users to the campaign' do
      team = create(:team, company_id: @company.id)
      expect do
        xhr :post, 'add_members', id: campaign.id, team_id: team.to_param, format: :js
        expect(response).to be_success
        expect(assigns(:campaign)).to eq(campaign)
        expect(assigns(:team_id)).to eq(team.id.to_s)
        campaign.reload
      end.to change(campaign.teams, :count).by(1)
      expect(campaign.teams).to match_array([team])
    end

    it 'should not assign users to the campaign if they are already part of the campaign' do
      campaign.users << @company_user
      expect do
        xhr :post, 'add_members', id: campaign.id, member_id: @company_user.to_param, format: :js
        expect(response).to be_success
        expect(assigns(:campaign)).to eq(campaign)
        campaign.reload
      end.not_to change(campaign.users, :count)
    end

    it 'should not assign teams to the campaign if they are already part of the campaign' do
      team = create(:team, company_id: @company.id)
      campaign.teams << team
      expect do
        xhr :post, 'add_members', id: campaign.id, team_id: team.to_param, format: :js
        expect(response).to be_success
        expect(assigns(:campaign)).to eq(campaign)
        campaign.reload
      end.not_to change(campaign.teams, :count)
    end
  end

  describe "GET 'tab'" do
    before do
      Kpi.create_global_kpis
    end
    it 'loads the staff tab' do
      campaign.users << @company_user
      campaign.teams << create(:team, company: @company)
      get 'tab', id: campaign.id, tab: 'staff'
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to render_template('_staff')
      expect(response).to render_template('_goalable_list')
    end

    it 'loads the places tab' do
      campaign.places << create(:place, is_custom_place: true, reference: nil)
      campaign.areas << create(:area, company: @company)
      get 'tab', id: campaign.id, tab: 'places'
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to render_template('_places')
      expect(response).to render_template('_goalable_list')
    end

    it 'loads the date_ranges tab' do
      campaign.date_ranges << create(:date_range, company: @company)
      get 'tab', id: campaign.id, tab: 'date_ranges'
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to render_template('_date_ranges')
      expect(response).to render_template('_goalable_list')
    end

    it 'loads the day_parts tab' do
      campaign.day_parts << create(:day_part, company: @company)
      get 'tab', id: campaign.id, tab: 'day_parts'
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to render_template('_day_parts')
      expect(response).to render_template('_goalable_list')
    end

    it 'loads the documents tab' do
      create(:attached_asset, attachable: campaign)
      get 'tab', id: campaign.id, tab: 'documents'
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to render_template('_documents')
    end
  end

  describe "POST 'add_kpi'" do
    let(:kpi) { create(:kpi, company: @company, name: 'custom tes kpi', kpi_type: 'number', capture_mechanism: 'integer') }

    it 'should associate the kpi to the campaign' do
      expect do
        xhr :post, 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :js
      end.to change(FormField, :count).by(1)

      expect(campaign.form_fields.count).to eq(1)
      field = campaign.form_fields.first
      expect(field.kpi_id).to eq(kpi.id)
      expect(field.type).to eq('FormField::Number')
      expect(field.name).to eq(kpi.name)
      expect(field.ordering).to eq(1)
    end

    it 'should NOT associate the kpi to the campaign if the campaing already have it assgined' do
      create(:form_field_number, fieldable: campaign, kpi_id: kpi.id, ordering: 1, name: 'impressions')
      expect do
        xhr :post, 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :js
      end.to_not change(FormField, :count)
    end

    it 'should automatically assign a correct ordering for the new field' do
      create(:form_field_number, fieldable: campaign, kpi_id: 999, ordering: 1, name: 'impressions')
      expect do
        xhr :post, 'add_kpi', id: campaign.id, kpi_id: kpi.id, format: :js
      end.to change(FormField, :count).by(1)

      expect(campaign.form_fields.count).to eq(2)
      field = FormField.last
      expect(field.ordering).to eq(2)
    end
  end

  describe "POST 'activity_type'" do
    let(:activity_type) { create(:activity_type, company: @company) }

    it 'should associate the kpi to the campaign' do
      expect do
        xhr :post, 'add_activity_type', id: campaign.id, activity_type_id: activity_type.id, format: :js
      end.to change(ActivityTypeCampaign, :count).by(1)
    end

    it 'should NOT associate the activity_type to the campaign if the campaing already have it assgined' do
      expect do
        xhr :post, 'remove_activity_type', id: campaign.id, activity_type_id: activity_type.id, format: :js
      end.to_not change(ActivityTypeCampaign, :count)
    end
  end

  describe "DELETE 'remove_activity_type'" do
    let(:activity_type) { create(:activity_type, company: @company) }
    it 'should disassociate the activity_type from the campaign' do
      campaign.activity_types << activity_type
      expect do
        xhr :post, 'remove_activity_type', id: campaign.id, activity_type_id: activity_type.id, format: :js
      end.to change(ActivityTypeCampaign, :count).by(-1)
      expect(response).to be_success
    end
  end

  describe "DELETE 'remove_kpi'" do
    let(:kpi) { create(:kpi, company: @company, name: 'custom tes kpi', kpi_type: 'number', capture_mechanism: 'integer') }

    it 'should disassociate the kpi from the campaign' do
      create(:form_field_number, fieldable: campaign, kpi_id: kpi.id, ordering: 1, name: 'impressions')
      expect do
        xhr :post, 'remove_kpi', id: campaign.id, kpi_id: kpi.id, format: :js
      end.to change(FormField, :count).by(-1)
      expect(response).to be_success
    end
  end

end
