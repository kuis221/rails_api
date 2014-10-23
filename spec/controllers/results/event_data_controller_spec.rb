require 'rails_helper'

describe Results::EventDataController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'should return http success' do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('_totals')
    end
  end

  describe "GET 'index'" do
    it 'queue the job for export the list' do
      expect do
        xhr :get, :index, format: :xls
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
    end
  end

  describe "GET 'list_export'", search: true do
    before do
      Kpi.create_global_kpis
    end
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    it 'should return an empty book with the correct headers' do
      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP', 'ACTIVE STATE',
         'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE']
      ])
    end

    it 'should include the event data results' do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      area = create(:area, name: 'My area', company: company)
      place = create(:place, name: 'Bar Prueba',
        city: 'Los Angeles', state: 'California', country: 'US', td_linx_code: '443321')
      area.places << create(:place, name: 'Los Angeles', types: ['political'],
        city: 'Los Angeles', state: 'California', country: 'US')
      campaign.areas << area
      event = create(:approved_event, company: company, campaign: campaign, place: place,
        start_date: '01/23/2019', end_date: '01/23/2019',
        start_time: '10:00 am', end_time: '12:00 pm')
      event.users << company_user
      team = create(:team, company: company, name: 'zteam')
      event.teams << team
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      set_event_results(event,
                        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
                        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)
      Sunspot.commit

      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP', 'ACTIVE STATE',
         'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE'],
        ['Test Campaign FY01', 'My area', '443321', 'Bar Prueba', 'Bar Prueba, Los Angeles, California, 12345',
         'Los Angeles', 'California', '12345', 'Active', 'Approved', 'Test User, zteam',
         "http://localhost:5100/events/#{event.id}", '2019-01-23T10:00', '2019-01-23T12:00',
         '2.0', '10', '11', '12', '99.99', '0.600', '0.400', '0.180', '0.200', '0.210', '0.190',
         '0.220']
      ])
    end

    it 'should include any custom kpis in the export' do
      kpi = create(:kpi, company: company, name: 'A Custom KPI')
      campaign.add_kpi kpi
      place = create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = build(:approved_event, company: company, campaign: campaign, place: place, start_date: '01/23/2013', end_date: '01/23/2013')
      event.result_for_kpi(kpi).value = '9876'
      event.save
      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE', 'A CUSTOM KPI'],
        ['Test Campaign FY01', nil, nil, 'Bar Prueba', 'Bar Prueba, Los Angeles, California, 12345',
         'Los Angeles', 'California', '12345', 'Active', 'Approved', nil, "http://localhost:5100/events/#{event.id}",
         '2013-01-23T10:00', '2013-01-23T12:00', '2.0', '0', '0', '0', '0.0', '0.000', '0.000', '0.000',
         '0.000', '0.000', '0.000', '0.000', '9876.0']
      ])
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows[0].elements.to_a('Cell/Data').map(&:text)).to include('A CUSTOM KPI')
        expect(rows[1].elements.to_a('Cell/Data').map(&:text)).to include('9876.0')
      end
    end

    it 'should include the event data results only for the given campaign' do
      Kpi.create_global_kpis
      custom_kpi = create(:kpi, name: 'Test KPI', company: company)
      checkbox_kpi = create(:kpi, name: 'Event Type', kpi_type: 'count', capture_mechanism: 'checkbox', company: company,
        kpis_segments: [
          create(:kpis_segment, text: 'Event Type Opt 1'),
          create(:kpis_segment, text: 'Event Type Opt 2'),
          create(:kpis_segment, text: 'Event Type Opt 3')])
      radio_kpi = create(:kpi, name: 'Radio Field Type', kpi_type: 'count', capture_mechanism: 'radio', company: company,
        kpis_segments: [
          create(:kpis_segment, text: 'Radio Field Opt 1'),
          create(:kpis_segment, text: 'Radio Field Opt 2'),
          create(:kpis_segment, text: 'Radio Field Opt 3')])
      campaign.assign_all_global_kpis
      campaign.add_kpi custom_kpi
      campaign.add_kpi checkbox_kpi
      campaign.add_kpi radio_kpi

      area = create(:area, name: 'Angeles Area', company: company)
      area.places << create(:place, name: 'Los Angeles', city: 'Los Angeles', state: 'California', country: 'US', types: ['locality'])
      campaign.areas << area
      place = create(:place, name: 'Bar Prueba',
        city: 'Los Angeles', state: 'California', country: 'US', td_linx_code: '344221')
      event = create(:approved_event, company: company, campaign: campaign, place: place,
        start_date: '01/23/2019', end_date: '01/23/2019',
        start_time: '10:00 am', end_time: '12:00 pm')
      event.users << company_user
      event.event_expenses.build(amount: 99.99, name: 'sample expense')
      event.result_for_kpi(custom_kpi).value = 8899
      event.result_for_kpi(checkbox_kpi).value = [checkbox_kpi.kpis_segments.first.id]
      event.result_for_kpi(radio_kpi).value = radio_kpi.kpis_segments.first.id

      set_event_results(event,
                        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
                        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)

      other_campaign = create(:campaign, company: company, name: 'Other Campaign FY01')
      other_campaign.assign_all_global_kpis
      event2 = create(:approved_event, company: company, campaign: other_campaign, place: place)
      set_event_results(event2,
                        impressions: 33, interactions: 44, samples: 55, gender_male: 66, gender_female: 34,
                        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20, ethnicity_hispanic: 21, ethnicity_white: 22)

      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP', 'ACTIVE STATE',
         'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE', 'AGE: < 12', 'AGE: 12 – 17', 'AGE: 18 – 24',
         'AGE: 25 – 34', 'AGE: 35 – 44', 'AGE: 45 – 54', 'AGE: 55 – 64', 'AGE: 65+', 'EVENT TYPE',
         'RADIO FIELD TYPE', 'TEST KPI'],
        ['Test Campaign FY01', 'Angeles Area', '344221', 'Bar Prueba', 'Bar Prueba, Los Angeles, California, 12345',
         'Los Angeles', 'California', '12345', 'Active', 'Approved', 'Test User', "http://localhost:5100/events/#{event.id}",
         '2019-01-23T10:00', '2019-01-23T12:00', '2.0', '10', '11',
         '12', '99.99', '0.600', '0.400', '0.180', '0.200', '0.210', '0.190', '0.220', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0',
         '0.0', '0.0', 'Event Type Opt 1', 'Radio Field Opt 1', '8899.0']
      ])
    end

    it 'should include any custom kpis from all the campaigns' do
      kpi = create(:kpi, company: company, name: 'A Custom KPI')
      kpi2 = create(:kpi, company: company, name: 'Another KPI')
      campaign2 = create(:campaign, company: company)
      campaign.add_kpi kpi
      campaign2.add_kpi kpi2

      event1 = build(:approved_event, company: company, campaign: campaign, start_date: '01/23/2013', end_date: '01/23/2013')
      event1.result_for_kpi(kpi).value = '9876'
      event1.save

      event2 = build(:approved_event, company: company, campaign: campaign2, start_date: '01/24/2013', end_date: '01/24/2013')
      event2.result_for_kpi(kpi2).value = '7654'
      event2.save

      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id, campaign2.id], format: :xls }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE', 'A CUSTOM KPI', 'ANOTHER KPI'],
        ['Test Campaign FY01', nil, nil, nil, nil, nil, nil, nil, 'Active', 'Approved', nil,
         "http://localhost:5100/events/#{event1.id}", '2013-01-23T10:00', '2013-01-23T12:00', '2.0', '0', '0', '0',
         '0.0', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '9876.0', nil],
        [campaign2.name, nil, nil, nil, nil, nil, nil, nil, 'Active', 'Approved', nil,
         "http://localhost:5100/events/#{event2.id}", '2013-01-24T10:00', '2013-01-24T12:00', '2.0', '0', '0',
         '0', '0.0', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', nil, '7654.0']
      ])
    end

    it 'should filter the results by campaign' do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      campaign2 = create(:campaign, company: company, name: 'Campaign not included')
      campaign2.assign_all_global_kpis

      event1 = create(:approved_event, company: company, campaign: campaign, start_date: '01/23/2013', end_date: '01/23/2013')
      set_event_results(event1, impressions: 111)
      event2 = create(:approved_event, company: company, campaign: campaign2, start_date: '01/24/2013', end_date: '01/24/2013')
      set_event_results(event2, impressions: 222)

      Sunspot.commit

      expect { xhr :get, 'index', format: :xls, campaign: [campaign.id] }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE', 'AGE: < 12', 'AGE: 12 – 17', 'AGE: 18 – 24',
         'AGE: 25 – 34', 'AGE: 35 – 44', 'AGE: 45 – 54', 'AGE: 55 – 64', 'AGE: 65+'],
        ['Test Campaign FY01', nil, nil, nil, nil, nil, nil, nil, 'Active', 'Approved', nil,
         "http://localhost:5100/events/#{event1.id}", '2013-01-23T10:00', '2013-01-23T12:00', '2.0', '111', '0', '0',
         '0.0', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.0', '0.0', '0.0', '0.0',
         '0.0', '0.0', '0.0', '0.0']
      ])
    end

    it 'should correctly include the segments for the percentage kpis' do
      kpi = build(:kpi, company: company, kpi_type: 'percentage', name: 'My KPI')
      seg1 = kpi.kpis_segments.build(text: 'Uno')
      seg2 = kpi.kpis_segments.build(text: 'Dos')
      kpi.save

      another_kpi = build(:kpi, company: company, kpi_type: 'number', name: 'My Other KPI')
      campaign.add_kpi kpi
      campaign.add_kpi another_kpi

      expect do
        @event1 = build(:approved_event, company: company, campaign: campaign, start_date: '01/23/2013', end_date: '01/23/2013')
        @event1.result_for_kpi(kpi).value = { seg1.id => '63', seg2.id => '37' }
        expect(@event1.save).to be_truthy

        @event2 = build(:approved_event, company: company, campaign: campaign, start_date: '01/24/2013', end_date: '01/24/2013')
        @event2.result_for_kpi(kpi).value = nil
        @event2.result_for_kpi(another_kpi).value = 134
        expect(@event2.save).to be_truthy
      end.to change(FormFieldResult, :count).by(3)

      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'URL', 'START', 'END', 'PROMO HOURS',
         'IMPRESSIONS', 'INTERACTIONS', 'SAMPLED', 'SPENT', 'FEMALE', 'MALE', 'ASIAN', 'BLACK/AFRICAN AMERICAN',
         'HISPANIC/LATINO', 'NATIVE AMERICAN', 'WHITE', 'MY KPI: UNO', 'MY KPI: DOS', 'MY OTHER KPI'],
        ['Test Campaign FY01', nil, nil, nil, nil, nil, nil, nil, 'Active', 'Approved', nil,
         "http://localhost:5100/events/#{@event1.id}", '2013-01-23T10:00', '2013-01-23T12:00', '2.0', '0', '0', '0',
         '0.0', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.63', '0.37', nil],
        ['Test Campaign FY01', nil, nil, nil, nil, nil, nil, nil, 'Active', 'Approved', nil,
         "http://localhost:5100/events/#{@event2.id}", '2013-01-24T10:00', '2013-01-24T12:00', '2.0', '0', '0', '0',
         '0.0', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.000', '0.0', '0.0', '134.0']
      ])
    end
  end
end
