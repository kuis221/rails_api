require 'spec_helper'

describe Results::EventDataController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it "should return http success" do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('totals')
    end
  end

  describe "GET 'index'" do
    it "queue the job for export the list" do
      expect{
        get :index, format: :xls
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
    end
  end

  describe "GET 'list_export'", search: true do
    before do
      Kpi.create_global_kpis
    end
    let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }
    it "should return an empty book with the correct headers" do
      expect { get 'index', format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows.count).to eql 1
        expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to eql [
          "CAMPAIGN NAME", "AREAS", "TD LINX CODE", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP","ACTIVE STATE",
          "EVENT STATUS", "TEAM MEMBERS","URL", "START", "END", "PROMO HOURS", "IMPRESSIONS",
          "INTERACTIONS", "SAMPLED", "SPENT", "FEMALE", "MALE", "ASIAN", "BLACK/AFRICAN AMERICAN",
          "HISPANIC/LATINO", "NATIVE AMERICAN", "WHITE"]
      end
    end

    it "should include the event data results" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      area = FactoryGirl.create(:area, name: 'My area', company: @company)
      place = FactoryGirl.create(:place, name: 'Bar Prueba',
        city: 'Los Angeles', state: 'California', country: 'US', td_linx_code: '443321')
      area.places << FactoryGirl.create(:place, name: 'Los Angeles', types: ['political'],
        city: 'Los Angeles', state: 'California', country: 'US')
      campaign.areas << area
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
      event.users << @company_user
      team = FactoryGirl.create(:team, company: @company, name: "zteam")
      event.teams << team
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      set_event_results(event,
        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)
      Sunspot.commit

      expect { get 'index', format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to eql [
          "Test Campaign FY01",'My area', '443321', "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345",
           "Los Angeles", "California", "12345", "Active", "Approved", "Test User, zteam",
           "http://localhost:5100/events/#{event.id}", "2019-01-23T10:00", "2019-01-23T12:00",
           "2.0", "10", "11", "12", "99.99", "0.600", "0.400", "0.180", "0.200", "0.210", "0.190",
           "0.220"]
        #1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should == ["", "Test Campaign FY01", "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345", "Los Angeles", "California", 12345.0,"Active", "Approved","Test User, zteam",Rails.application.routes.url_helpers.event_url(event), "Wed, 23 Jan 2019 09:59:59 +0000", "Wed, 23 Jan 2019 12:00:00 +0000", 2.0, 10.0, 11.0, 12.0, 99.99, "60.00%", "40.00%", "18.00%", "20.00%", "21.00%", "19.00%", "22.00%"]
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

      expect { get 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to include('A CUSTOM KPI')
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to include('9876.0')
      end
    end


    it "should include the event data results only for the given campaign" do
      Kpi.create_global_kpis
      custom_kpi = FactoryGirl.create(:kpi, name: 'Test KPI', company: @company)
      checkbox_kpi = FactoryGirl.create(:kpi, name: 'Event Type', kpi_type: "count", capture_mechanism: "checkbox", company: @company,
        kpis_segments: [
          FactoryGirl.create(:kpis_segment, text: 'Event Type Opt 1'),
          FactoryGirl.create(:kpis_segment, text: 'Event Type Opt 2'),
          FactoryGirl.create(:kpis_segment, text: 'Event Type Opt 3')])
      radio_kpi = FactoryGirl.create(:kpi, name: 'Radio Field Type', kpi_type: "count", capture_mechanism: "radio", company: @company,
        kpis_segments: [
          FactoryGirl.create(:kpis_segment, text: 'Radio Field Opt 1'),
          FactoryGirl.create(:kpis_segment, text: 'Radio Field Opt 2'),
          FactoryGirl.create(:kpis_segment, text: 'Radio Field Opt 3')])
      campaign.assign_all_global_kpis
      campaign.add_kpi custom_kpi
      campaign.add_kpi checkbox_kpi
      campaign.add_kpi radio_kpi

      area = FactoryGirl.create(:area, name: 'Angeles Area', company: @company)
      area.places << FactoryGirl.create(:place, name: 'Los Angeles', city: 'Los Angeles', state: 'California', country: 'US', types: ['locality'])
      campaign.areas << area
      place = FactoryGirl.create(:place, name: 'Bar Prueba',
        city: 'Los Angeles', state: 'California', country: 'US', td_linx_code: '344221')
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
      event.users << @company_user
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      event.result_for_kpi(custom_kpi).value = 8899
      event.result_for_kpi(checkbox_kpi).value = [checkbox_kpi.kpis_segments.first.id]
      event.result_for_kpi(radio_kpi).value = radio_kpi.kpis_segments.first.id

      set_event_results(event,
        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)

      other_campaign = FactoryGirl.create(:campaign, company: @company, name: 'Other Campaign FY01')
      other_campaign.assign_all_global_kpis
      event2 = FactoryGirl.create(:approved_event, company: @company, campaign: other_campaign, place: place)
      set_event_results(event2,
        impressions: 33, interactions: 44, samples: 55, gender_male: 66, gender_female: 34,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)

      Sunspot.commit

      expect { get 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows.count).to eql 2
        expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to match_array [
          "CAMPAIGN NAME","AREAS","TD LINX CODE", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP", "ACTIVE STATE",
          "EVENT STATUS", "TEAM MEMBERS","URL","START", "END", "PROMO HOURS", "IMPRESSIONS",
          "INTERACTIONS", "SAMPLED", "SPENT", "FEMALE", "MALE", "ASIAN", "BLACK/AFRICAN AMERICAN",
          "HISPANIC/LATINO", "NATIVE AMERICAN", "WHITE","AGE: < 12", "AGE: 12 – 17", "AGE: 18 – 24",
          "AGE: 25 – 34", "AGE: 35 – 44", "AGE: 45 – 54", "AGE: 55 – 64", "AGE: 65+", "TEST KPI", "EVENT TYPE",
          "RADIO FIELD TYPE"]
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to match_array [
          "Test Campaign FY01", "Angeles Area", "344221", "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345",
          "Los Angeles", "California", "12345","Active", "Approved","Test User","http://localhost:5100/events/#{event.id}",
          "2019-01-23T10:00", "2019-01-23T12:00", "2.0", "10", "11",
          "12", "99.99", "0.600", "0.400", "0.180", "0.200", "0.210", "0.190", "0.220","0.0", "0.0", "0.0", "0.0", "0.0", "0.0",
          "0.0", "0.0", '8899.0', 'Event Type Opt 1', 'Radio Field Opt 1']
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

      expect { get 'index', campaign: [campaign.id, campaign2.id], format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to include('A CUSTOM KPI', 'ANOTHER KPI')
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to include('9876.0')
        expect(rows[2].elements.to_a('Cell/Data').map{|d| d.text }).to include('7654.0')
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

      expect { get 'index', format: :xls, campaign: [campaign.id] }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows.count).to eql 2
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to include('Test Campaign FY01')
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to_not include('Campaign not included')
      end
    end

    it "should correctly include the segments for the percentage kpis" do
      kpi = FactoryGirl.build(:kpi, company: @company, kpi_type: 'percentage', name: 'My KPI')
      seg1 = kpi.kpis_segments.build(text: 'Uno')
      seg2 = kpi.kpis_segments.build(text: 'Dos')
      kpi.save

      another_kpi = FactoryGirl.build(:kpi, company: @company, kpi_type: 'number', name: 'My Other KPI')
      campaign.add_kpi kpi
      campaign.add_kpi another_kpi

      expect{
        event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = {seg1.id => '63', seg2.id => '37'}
        expect(event.save).to be_truthy

        event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = nil
        event.result_for_kpi(another_kpi).value = 134
        expect(event.save).to be_truthy
      }.to change(FormFieldResult, :count).by(3)

      Sunspot.commit

      expect { get 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows.count).to eql 3
        expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to include('MY KPI: UNO', 'MY KPI: DOS')
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to include('0.63', '0.37')
        expect(rows[2].elements.to_a('Cell/Data').map{|d| d.text }).to include('134.0')
      end
    end
  end
end