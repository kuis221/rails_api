require 'spec_helper'

describe Results::EventDataController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'items'" do
    it "should return http success" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      event = FactoryGirl.create(:event, campaign: campaign, company: @company, start_date: "01/23/2019", end_date: "01/23/2019", start_time: '8:00pm', end_time: '11:00pm')
      set_event_results(event,
        impressions: 100,
        interactions: 101,
        samples: 102,
        gender_male: 35,
        gender_female: 65,
        ethnicity_asian: 15,
        ethnicity_native_american: 23,
        ethnicity_black: 24,
        ethnicity_hispanic: 26,
        ethnicity_white: 12
      )

      Sunspot.commit

      without_current_user { FactoryGirl.create(:event, company_id: @company.id + 1) } # An event in other company

      get 'items'
      expect(response).to be_success
      expect(response).to render_template('totals')

      expect(assigns(:data_totals)['events_count']).to eq(1)
      expect(assigns(:data_totals)['promo_hours']).to eq(3)
      expect(assigns(:data_totals)['impressions']).to eq(100)
      expect(assigns(:data_totals)['interactions']).to eq(101)
      expect(assigns(:data_totals)['samples']).to eq(102)
      expect(assigns(:data_totals)['gender_female']).to eq(65)
      expect(assigns(:data_totals)['gender_male']).to eq(35)
      expect(assigns(:data_totals)['ethnicity_asian']).to eq(15)
      expect(assigns(:data_totals)['ethnicity_black']).to eq(24)
      expect(assigns(:data_totals)['ethnicity_hispanic']).to eq(26)
      expect(assigns(:data_totals)['ethnicity_native_american']).to eq(23)
      expect(assigns(:data_totals)['ethnicity_white']).to eq(12)
    end
  end

end