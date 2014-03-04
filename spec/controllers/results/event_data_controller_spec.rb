require 'spec_helper'
require 'roo'

describe Results::EventDataController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'items'" do
    it "should return http success" do
      get 'items'
      response.should be_success
      response.should render_template('totals')
    end
  end

  describe "GET 'index'" do
    it "queue the job for export the list" do
      expect{
        get :index, format: :xlsx
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      ListExportWorker.should have_queued(export.id)
    end
  end

  describe "GET 'list_export'", search: true do
    before do
      Kpi.create_global_kpis
    end
    let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }
    it "should return an empty book with the correct headers" do
      expect { get 'index', format: :xlsx }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        oo.last_row.should == 2
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should == ["", "CAMPAIGN NAME", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP", "START", "END", "PROMO HOURS", "IMPRESSIONS", "INTERACTIONS", "SAMPLED", "SPENT", "FEMALE", "MALE", "ASIAN", "BLACK/AFRICAN AMERICAN", "HISPANIC/LATINO", "NATIVE AMERICAN", "WHITE", "TEAM MEMBERS"]
        1.upto(oo.last_column).map{|col| oo.cell(2, col) }.should == ["TOTALS", "0 EVENTS", "", "", "", "", "", "", "", 0.0, 0.0, 0.0, 0.0, "$0.00", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%",""]
      end
    end

    it "should include the event data results" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      place = FactoryGirl.create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
      team = FactoryGirl.create(:team, company: @company)
      event.teams << team
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      set_event_results(event,
        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)
      Sunspot.commit

      expect { get 'index', format: :xlsx }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        oo.last_row.should == 3
        1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should == ["", "Test Campaign FY01", "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345", "Los Angeles", "California", 12345.0, "Wed, 23 Jan 2019 09:59:59 +0000", "Wed, 23 Jan 2019 12:00:00 +0000", 2.0, 10.0, 11.0, 12.0, 99.99, "60.00%", "40.00%", "18.00%", "20.00%", "21.00%", "19.00%", "22.00%", (event.teams + event.users).sort_by(&:name).map(&:name).join(', ')]
      end
    end

    it "should include any custom kpis in the export" do
      kpi = FactoryGirl.create(:kpi, company: @company, name: 'A Custom KPI')
      campaign.add_kpi kpi
      place = FactoryGirl.create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign, place: place)
      event.result_for_kpi(kpi).value = '9876'
      event.save
      Sunspot.commit

      expect { get 'index', campaign: [campaign.id], format: :xlsx }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should include('A CUSTOM KPI')
        1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should include(9876)
      end
    end


    it "should include the event data results only for the given campaign" do
      Kpi.create_global_kpis
      custom_kpi = FactoryGirl.create(:kpi, name: 'Test KPI', company: @company)
      campaign.assign_all_global_kpis
      campaign.add_kpi custom_kpi
      area = FactoryGirl.create(:area, name: 'Angeles Area', company: @company)
      area.places << FactoryGirl.create(:place, name: 'Los Angeles', city: 'Los Angeles', state: 'California', country: 'US', types: ['locality'])
      campaign.areas << area
      place = FactoryGirl.create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      event.result_for_kpi(custom_kpi).value = 8899
      set_event_results(event,
        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)

      other_campaign = FactoryGirl.create(:campaign, company: @company, name: 'Other Campaign FY01')
      other_campaign.assign_all_global_kpis
      event = FactoryGirl.create(:approved_event, company: @company, campaign: other_campaign, place: place)
      set_event_results(event,
        impressions: 33, interactions: 44, samples: 55, gender_male: 66, gender_female: 34,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)

      Sunspot.commit

      expect { get 'index', campaign: [campaign.id], format: :xlsx }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        oo.last_row.should == 3
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should == ["", "CAMPAIGN NAME", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP", "START", "END", "PROMO HOURS", "IMPRESSIONS", "INTERACTIONS", "SAMPLED", "SPENT", "FEMALE", "MALE", "ASIAN", "BLACK/AFRICAN AMERICAN", "HISPANIC/LATINO", "NATIVE AMERICAN", "WHITE","TEAM MEMBERS","AGE: < 12", "AGE: 12 – 17", "AGE: 18 – 24", "AGE: 25 – 34", "AGE: 35 – 44", "AGE: 45 – 54", "AGE: 55 – 64", "AGE: 65+", "TEST KPI"]
        1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should == ["", "Test Campaign FY01", "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345", "Los Angeles", "California", 12345.0, "Wed, 23 Jan 2019 09:59:59 +0000", "Wed, 23 Jan 2019 12:00:00 +0000", 2.0, 10.0, 11.0, 12.0, 99.99, "60.00%", "40.00%", "18.00%", "20.00%", "21.00%", "19.00%", "22.00%",(event.teams + event.users).sort_by(&:name).map(&:name).join(', '),nil, nil, nil, nil, nil, nil, nil, nil, 8899]
      end
    end

    it "should include any custom kpis from all the campaigns" do
      kpi = FactoryGirl.create(:kpi, company: @company, name: 'A Custom KPI')
      kpi2 = FactoryGirl.create(:kpi, company: @company, name: 'Another KPI')
      campaign2 = FactoryGirl.create(:campaign, company: @company)
      campaign.add_kpi kpi
      campaign2.add_kpi kpi2

      event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign)
      event.result_for_kpi(kpi).value = '9876'
      event.save

      event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign2)
      event.result_for_kpi(kpi2).value = '7654'
      event.save

      Sunspot.commit

      expect { get 'index', campaign: [campaign.id, campaign2.id], format: :xlsx }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should include('A CUSTOM KPI')
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should include('ANOTHER KPI')
        1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should include(9876)
        1.upto(oo.last_column).map{|col| oo.cell(4, col) }.should include(7654)
      end
    end

    it "should filter the results by campaign" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      campaign2 = FactoryGirl.create(:campaign, company: @company, name: 'Campaign not included')
      campaign2.assign_all_global_kpis

      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign)
      set_event_results(event, impressions: 111)
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign2)
      set_event_results(event, impressions: 222)

      Sunspot.commit

      expect { get 'index', format: :xlsx, campaign: [campaign.id] }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        oo.last_row.should == 3
        1.upto(oo.last_column).map{|col| oo.cell(oo.last_row, col) }.should include('Test Campaign FY01')
        1.upto(oo.last_column).map{|col| oo.cell(oo.last_row, col) }.should_not include('Campaign not included')
      end
    end

    it "should correctly include the segments for the percentage kpis" do
      kpi = FactoryGirl.build(:kpi, company: @company, kpi_type: 'percentage', name: 'My KPI')
      kpi.kpis_segments.build(text: 'Uno')
      kpi.kpis_segments.build(text: 'Dos')
      kpi.save
      campaign.add_kpi kpi

      event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign)
      results = event.result_for_kpi(kpi)
      results.first.value = '112233'
      results.last.value = '445566'
      event.save

      Sunspot.commit

      expect { get 'index', campaign: [campaign.id], format: :xlsx }.to change(ListExport, :count).by(1)
      woorbook_from_last_export do |oo|
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should include('MY KPI: UNO')
        1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should include('MY KPI: DOS')
        1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should include(112233)
        1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should include(445566)
      end
    end
  end
end