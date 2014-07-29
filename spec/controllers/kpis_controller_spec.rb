require 'spec_helper'

describe KpisController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', campaign_id: campaign.to_param, format: :js
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to be_success
    end
  end

  describe "GET 'edit'" do
    let(:kpi){ FactoryGirl.create(:kpi, company: @company) }
    it "returns http success" do
      get 'edit',  campaign_id: campaign.to_param, id: kpi.to_param, format: :js
      expect(assigns(:campaign)).to eq(campaign)
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "should not render form_dialog if no errors" do
      expect {
        post 'create', campaign_id: campaign.to_param, kpi: {name: 'Test kpi', description: 'Test kpi description', kpi_type: 'number'}, format: :js
         expect(response).to be_success
      }.to change(Kpi, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template(:form_dialog)

      kpi = Kpi.last
      expect(kpi.name).to eq('Test kpi')
      expect(kpi.description).to eq('Test kpi description')
    end

    it "should not render the form_dialog template if errors" do
      expect {
        post 'create', campaign_id: campaign.to_param, format: :js, kpi: {}
      }.not_to change(Kpi, :count)
      expect(response).to render_template(:create)
      expect(response).not_to render_template(:form_dialog)
      assigns(:kpi).errors.count > 0
    end
  end

  describe "PUT 'update'" do
    let(:kpi){ FactoryGirl.create(:kpi, company: @company) }
    it "must update the kpi attributes" do
      kpi.save
      expect {
        expect {
          put 'update', campaign_id: campaign.to_param, id: kpi.to_param, kpi: {name: 'Test kpi', description: 'Test kpi description', goals_attributes: [{goalable_id: campaign.to_param, goalable_type: 'Campaign', value: 13}]}, format: :js
        }.to change(Goal, :count).by(1)
      }.to_not change(Kpi, :count)
      expect(response).to render_template(:update)
      expect(response).not_to render_template(:form_dialog)

      expect(campaign.goals.for_kpi(kpi).value).to eq(13)
      expect(assigns(:kpi)).to eq(kpi)
      kpi.reload
      expect(kpi.name).to eq('Test kpi')
      expect(kpi.description).to eq('Test kpi description')
    end

    it "must update the goals for kpis that already have a goal" do
      kpi.save
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 33
      expect(goal.save).to be_truthy

      expect {
        expect {
          put 'update', campaign_id: campaign.to_param, id: kpi.to_param, kpi: {name: 'Test kpi', description: 'Test kpi description', goals_attributes: [{id: goal.id, goalable_id: campaign.to_param, goalable_type: 'Campaign', value: 44}]}, format: :js
        }.to_not change(Goal, :count)
      }.to_not change(Kpi, :count)
      expect(response).to render_template(:update)
      expect(response).not_to render_template(:form_dialog)

      expect(campaign.reload.goals.for_kpi(kpi).value).to eq(44)
    end


    it "should create the associated segments" do
      kpi.save
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 33
      expect(goal.save).to be_truthy

      expect {
        expect {
          put 'update', campaign_id: campaign.to_param, id: kpi.to_param, kpi: {name: 'Test kpi', kpi_type: 'count', description: 'Test kpi description', kpis_segments_attributes: [{text: 'An option'}, {text: 'Another option'}]}, format: :js
        }.to change(KpisSegment, :count).by(2)
      }.to_not change(Kpi, :count)
      expect(response).to render_template(:update)
      expect(response).not_to render_template(:form_dialog)
    end

    it "should save the goals for the associated segments" do
      kpi.save
      expect {
        expect {
          expect {
            put 'update', campaign_id: campaign.to_param, id: kpi.to_param, kpi: {name: 'Test kpi', kpi_type: 'count', description: 'Test kpi description',
              kpis_segments_attributes: [
                {text: 'An option', goals_attributes: [{goalable_id: campaign.to_param, goalable_type: 'Campaign', value: 44, kpi_id: kpi.id}]},
                {text: 'Another option', goals_attributes: [{goalable_id: campaign.to_param, goalable_type: 'Campaign', value: 55, kpi_id: kpi.id}]}
              ]}, format: :js
          }.to change(Goal, :count).by(2)
        }.to change(KpisSegment, :count).by(2)
      }.to_not change(Kpi, :count)
      expect(response).to render_template(:update)
      expect(response).not_to render_template(:form_dialog)
    end


    it "should not allow update global kpis' attributes" do
      Kpi.create_global_kpis
      put 'update', campaign_id: campaign.to_param, id: Kpi.impressions.to_param, kpi: {name: 'Test kpi', description: 'Test kpi description'}, format: :js
      expect(response).to render_template(:update)
      expect(response).not_to render_template(:form_dialog)
      expect(assigns(:kpi)).to eq(Kpi.impressions)
      Kpi.impressions.reload
      expect(Kpi.impressions.name).not_to eq('Test kpi')
      expect(Kpi.impressions.description).not_to eq('Test kpi description')
    end
  end
end
