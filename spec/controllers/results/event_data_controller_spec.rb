require 'spec_helper'
require 'roo'

class Results::EventDataController
  def test_export
    exporter = ListExport.create(controller: 'Results::EventDataController', company_user: @company_user, export_format: 'xlsx', params: search_params)
    send_data export_list(exporter), filename: 'test.xlsx'
  end
end

class EventDatum < Event
end

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

  describe "GET 'index'", js: true, search: true do
    it "queue the job for export the list" do
      expect{
        get :index, format: :xlsx
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      ListExportWorker.should have_queued(export.id)
    end
  end

  describe "GET 'list_export'", search: true do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }
    it "should return an empty book with the correct headers" do
      with_routing do |map|
        map.draw { get ':controller/:action' }
        get 'test_export'
        woorbook_from_response do |oo|
          oo.last_row.should == 2
          1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should == ["", "CAMPAIGN NAME", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP", "START DATE", "PROMO HOURS", "IMPRESSIONS", "INTERACTIONS", "SAMPLED", "SPENT", "FEMALE", "MALE", "ASIAN", "BLACK/AFRICAN AMERICAN", "HISPANIC/LATINO", "NATIVE AMERICAN", "WHITE"]
          1.upto(oo.last_column).map{|col| oo.cell(2, col) }.should == ["TOTALS", "0 EVENTS", "", "", "", "", "", "", 0.0, 0.0, 0.0, 0.0, "$0.00", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%"]
        end
      end
    end

    it "should include the event data results" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      place = FactoryGirl.create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      set_event_results(event,
        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)
      Sunspot.commit

      with_routing do |map|
        map.draw { get ':controller/:action' }
        get 'test_export'
        woorbook_from_response do |oo|
          oo.last_row.should == 3
          1.upto(oo.last_column).map{|col| oo.cell(3, col) }.should == ["", "Test Campaign FY01", "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345", "Los Angeles", "California", 12345.0, "WED Jan 23, 2019", 2.0, 10.0, 11.0, 12.0, 99.99, "60.00%", "40.00%", "18.00%", "20.00%", "21.00%", "19.00%", "22.00%"]
        end
      end
    end
  end

  def woorbook_from_response
    File.open('tmp/g.xlsx', 'w'){|f| f.write(response.body) }
    file = Tempfile.open(['export', '.xlsx'], Rails.root.join('tmp') ) do |file|
      file.print(response.body)
      file.flush
      yield Roo::Excelx.new(file.path)
    end
  end
end