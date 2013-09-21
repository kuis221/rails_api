require 'spec_helper'

describe Results::EventDataController, search: true do
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

      FactoryGirl.create(:event, company_id: @company.id + 1) # An event in other company

      get 'items'
      response.should be_success
      response.should render_template('totals')

      assigns(:data_totals)['events_count'].should == 1
      assigns(:data_totals)['promo_hours'].should == 3
      assigns(:data_totals)['impressions'].should == 100
      assigns(:data_totals)['interactions'].should == 101
      assigns(:data_totals)['samples'].should == 102
      assigns(:data_totals)['gender_female'].should == 65
      assigns(:data_totals)['gender_male'].should == 35
      assigns(:data_totals)['ethnicity_asian'].should == 15
      assigns(:data_totals)['ethnicity_black'].should == 24
      assigns(:data_totals)['ethnicity_hispanic'].should == 26
      assigns(:data_totals)['ethnicity_native_american'].should == 23
      assigns(:data_totals)['ethnicity_white'].should == 12
    end
  end

end