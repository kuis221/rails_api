require 'rails_helper'

describe Results::EventDataController, type: :controller do
  let(:user) { company_user.user }
  let(:company) { create(:company) }
  let(:company_user) { create(:company_user, company: company, role: role) }
  let(:role) { create(:role, company: company) }

  before { sign_in_as_user company_user }

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
        xhr :get, :index, format: :csv
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

    it 'should return an empty csv with the correct headers' do
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT']
      ])
    end

    it 'should include the event data results' do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      area = create(:area, name: 'My area', company: company)
      place = create(:place, name: 'Bar Prueba',
                             city: 'Los Angeles', state: 'California', country: 'US',
                             td_linx_code: '443321')
      area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      campaign.areas << area
      event = create(:approved_event, company: company, campaign: campaign, place: place,
                                      start_date: '01/23/2019', end_date: '01/23/2019',
                                      start_time: '10:00 am', end_time: '12:00 pm',
                                      event_expenses: [
                                        build(:event_expense, category: 'Entertainment', amount: 99.99)
                                      ])
      event.users << company_user
      team = create(:team, company: company, name: 'zteam')
      event.teams << team
      set_event_results(event,
                        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
                        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20,
                        ethnicity_hispanic: 21, ethnicity_white: 22)
      contact1 = create(:contact, first_name: 'Guillermo', last_name: 'Vargas',
                                  email: 'guilleva@gmail.com', company: company)
      contact2 = create(:contact, first_name: 'Chris', last_name: 'Jaskot',
                                  email: 'cjaskot@gmail.com', company: company)
      create(:contact_event, event: event, contactable: contact1)
      create(:contact_event, event: event, contactable: contact2)

      Sunspot.commit

      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'ENTERTAINMENT'],
        ['Test Campaign FY01', 'My area', '="443321"', 'Bar Prueba',
         'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US', 'Los Angeles', 'California', '12345',
         'Active', 'Approved', 'Test User, zteam', 'Chris Jaskot, Guillermo Vargas',
         "http://test.host/events/#{event.id}", '2019-01-23 10:00', '2019-01-23 12:00',
         nil, nil, '2.00', '99.99', '99.99']
      ])
    end

    it 'should include any custom kpis in the export' do
      kpi = create(:kpi, company: company, name: 'A Custom KPI')
      campaign.add_kpi kpi
      place = create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = build(:approved_event, campaign: campaign, place: place,
                                     start_date: '01/23/2013', end_date: '01/23/2013')
      event.result_for_kpi(kpi).value = '9876'
      event.save
      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id], format: :csv }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'A CUSTOM KPI'],
        ['Test Campaign FY01', '', nil, 'Bar Prueba', 'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US',
         'Los Angeles', 'California', '12345', 'Active', 'Approved', '', '',
         "http://test.host/events/#{event.id}", '2013-01-23 10:00', '2013-01-23 12:00', nil, nil, '2.00',
         '0', '9876.0']
      ])
    end

    it 'includes any custom fields for the campaigns in the custom filter' do
      cf = create(:custom_filter, owner: company_user, filters: "campaign[]=#{campaign.id}")
      field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
      place = create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
      event = build(:approved_event, campaign: campaign, place: place,
                                     start_date: '01/23/2013', end_date: '01/23/2013')
      event.results_for([field]).first.value = '9876'
      event.save
      Sunspot.commit

      expect { xhr :get, 'index', cfid: [cf.id], format: :csv }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'MY NUMERIC FIELD'],
        ['Test Campaign FY01', '', nil, 'Bar Prueba', 'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US',
         'Los Angeles', 'California', '12345', 'Active', 'Approved', '', '',
         "http://test.host/events/#{event.id}", '2013-01-23 10:00', '2013-01-23 12:00', nil, nil, '2.00', '0',
         '9876.0']
      ])
    end

    describe 'when logged in as a non admin user' do
      let(:role) { create(:non_admin_role) }

      before { add_permissions [[:index_results, 'EventData']] }

      it 'only include data from campaigns included in the custom filter' do
        place = create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
        campaign2 = create(:campaign, company: company)

        company_user.places << place
        company_user.campaigns << [campaign, campaign2]
        create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
        create(:form_field_number, name: 'Other Field', fieldable: campaign2)

        cf = create(:custom_filter, owner: company_user, filters: "campaign[]=#{campaign.id}")

        Sunspot.commit

        expect { xhr :get, 'index', cfid: [cf.id], format: :csv }.to change(ListExport, :count).by(1)

        ResqueSpec.perform_all(:export)
        expect(ListExport.last).to have_rows([
          ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
           'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
           'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'MY NUMERIC FIELD']
        ])
      end
    end

    it 'should include the event data results only for the given campaign' do
      Kpi.create_global_kpis
      custom_kpi = create(:kpi, name: 'Test KPI', company: company)
      checkbox_kpi = create(:kpi,
                            name: 'Event Type', kpi_type: 'count', capture_mechanism: 'checkbox',
                            company: company,
                            kpis_segments: [
                              create(:kpis_segment, text: 'Event Type Opt 1'),
                              create(:kpis_segment, text: 'Event Type Opt 2'),
                              create(:kpis_segment, text: 'Event Type Opt 3')])
      radio_kpi = create(:kpi,
                         name: 'Radio Field Type', kpi_type: 'count', capture_mechanism: 'radio',
                         company: company,
                         kpis_segments: [
                           create(:kpis_segment, text: 'Radio Field Opt 1'),
                           create(:kpis_segment, text: 'Radio Field Opt 2'),
                           create(:kpis_segment, text: 'Radio Field Opt 3')])
      campaign.assign_all_global_kpis
      campaign.add_kpi custom_kpi
      campaign.add_kpi checkbox_kpi
      campaign.add_kpi radio_kpi

      area = create(:area, name: 'Angeles Area', company: company)
      area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      campaign.areas << area
      place = create(:place, name: 'Bar Prueba',
                             city: 'Los Angeles', state: 'California', country: 'US',
                             td_linx_code: '344221')
      event = create(:approved_event, company: company, campaign: campaign, place: place,
                                      start_date: '01/23/2019', end_date: '01/23/2019',
                                      start_time: '10:00 am', end_time: '12:00 pm',
                                      event_expenses: [
                                        build(:event_expense, category: 'Entertainment', amount: 99.99)
                                      ])
      event.users << company_user
      event.result_for_kpi(custom_kpi).value = 8899
      event.result_for_kpi(checkbox_kpi).value = [checkbox_kpi.kpis_segments.first.id]
      event.result_for_kpi(radio_kpi).value = radio_kpi.kpis_segments.first.id

      set_event_results(event,
                        impressions: 10, interactions: 11, samples: 12, gender_male: 40, gender_female: 60,
                        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20,
                        ethnicity_hispanic: 21, ethnicity_white: 22)

      other_campaign = create(:campaign, company: company, name: 'Other Campaign FY01')
      other_campaign.assign_all_global_kpis
      event2 = create(:approved_event, company: company, campaign: other_campaign, place: place)
      set_event_results(event2,
                        impressions: 33, interactions: 44, samples: 55, gender_male: 66, gender_female: 34,
                        ethnicity_asian: 18, ethnicity_native_american: 19, ethnicity_black: 20,
                        ethnicity_hispanic: 21, ethnicity_white: 22)
      contact1 = create(:contact, first_name: 'Guillermo', last_name: 'Vargas',
                                  email: 'guilleva@gmail.com', company: company)
      contact2 = create(:contact, first_name: 'Chris', last_name: 'Jaskot',
                                  email: 'cjaskot@gmail.com', company: company)
      create(:contact_event, event: event, contactable: contact1)
      create(:contact_event, event: event, contactable: contact2)

      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id], format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'ENTERTAINMENT', 'GENDER: FEMALE',
         'GENDER: MALE', 'AGE: < 12', 'AGE: 12 – 17', 'AGE: 18 – 24', 'AGE: 25 – 34', 'AGE: 35 – 44',
         'AGE: 45 – 54', 'AGE: 55 – 64', 'AGE: 65+', 'ETHNICITY/RACE: ASIAN',
         'ETHNICITY/RACE: BLACK / AFRICAN AMERICAN', 'ETHNICITY/RACE: HISPANIC / LATINO',
         'ETHNICITY/RACE: NATIVE AMERICAN', 'ETHNICITY/RACE: WHITE', 'IMPRESSIONS', 'INTERACTIONS',
         'SAMPLES', 'TEST KPI', 'EVENT TYPE: EVENT TYPE OPT 1', 'EVENT TYPE: EVENT TYPE OPT 2',
         'EVENT TYPE: EVENT TYPE OPT 3', 'RADIO FIELD TYPE'],
        ['Test Campaign FY01', 'Angeles Area', '="344221"', 'Bar Prueba',
         'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US',
         'Los Angeles', 'California', '12345', 'Active', 'Approved', 'Test User',
         'Chris Jaskot, Guillermo Vargas', "http://test.host/events/#{event.id}",
         '2019-01-23 10:00', '2019-01-23 12:00', nil, nil, '2.00', '99.99', '99.99', '0.6',
         '0.4', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.18', '0.2', '0.21',
         '0.19', '0.22', '10.0', '11.0', '12.0', '8899.0', 'Yes', nil, nil, 'Radio Field Opt 1']
      ])
    end

    it 'should include the event data results only for the campaigns associatted to a given brand' do
      custom_kpi = create(:kpi, name: 'Test KPI 1', company: company)
      custom_kpi2 = create(:kpi, name: 'Test KPI 2', company: company)
      brand = create(:brand, company: company)

      campaign.brands << brand
      campaign.add_kpi custom_kpi

      campaign2 = create(:campaign, company: company)
      campaign2.add_kpi custom_kpi2

      area = create(:area, name: 'Angeles Area', company: company)
      area.places << create(:place, name: 'Los Angeles', city: 'Los Angeles', state: 'California',
                                    country: 'US', types: ['locality'])
      campaign.areas << area
      place = create(:place, name: 'Bar Prueba',
                             city: 'Los Angeles', state: 'California', country: 'US',
                             td_linx_code: '344221')
      event = create(:approved_event, company: company, campaign: campaign, place: place,
                                      start_date: '01/23/2019', end_date: '01/23/2019',
                                      start_time: '10:00 am', end_time: '12:00 pm')
      event.result_for_kpi(custom_kpi).value = 8899
      event.save

      event2 = create(:approved_event, company: company, campaign: campaign2, place: place,
                                       start_date: '01/23/2019', end_date: '01/23/2019',
                                       start_time: '10:00 am', end_time: '12:00 pm')
      event2.result_for_kpi(custom_kpi2).value = 1234
      event2.save

      Sunspot.commit

      expect { xhr :get, 'index', brand: [brand.id], format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'TEST KPI 1'],
        ['Test Campaign FY01', 'Angeles Area', '="344221"', 'Bar Prueba',
         'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US', 'Los Angeles', 'California',
         '12345', 'Active', 'Approved', '', '', "http://test.host/events/#{event.id}",
         '2019-01-23 10:00', '2019-01-23 12:00', nil, nil, '2.00', '0', '8899.0']
      ])
    end

    it 'should include any custom kpis from all the campaigns' do
      kpi = create(:kpi, company: company, name: 'A Custom KPI')
      kpi2 = create(:kpi, company: company, name: 'Another KPI')
      campaign2 = create(:campaign, company: company)
      campaign.add_kpi kpi
      campaign2.add_kpi kpi2

      event1 = build(:approved_event, campaign: campaign,
                                      start_date: '01/23/2013', end_date: '01/23/2013')
      event1.result_for_kpi(kpi).value = '9876'
      event1.save

      event2 = build(:approved_event, campaign: campaign2,
                                      start_date: '01/24/2013', end_date: '01/24/2013')
      event2.result_for_kpi(kpi2).value = '7654'
      event2.save

      Sunspot.commit

      expect do
        xhr :get, 'index', campaign: [campaign.id, campaign2.id], format: :csv
      end.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY',
         'STATE', 'ZIP', 'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL',
         'START', 'END', 'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'A CUSTOM KPI', 'ANOTHER KPI'],
        ['Test Campaign FY01', nil, nil, nil, '', nil, nil, nil, nil, 'Active', 'Approved', '', '',
         "http://test.host/events/#{event1.id}", '2013-01-23 10:00', '2013-01-23 12:00', nil, nil,
         '2.00', '0', '9876.0', nil],
        [campaign2.name, nil, nil, nil, '', nil, nil, nil, nil, 'Active', 'Approved', '', '',
         "http://test.host/events/#{event2.id}", '2013-01-24 10:00', '2013-01-24 12:00', nil, nil,
         '2.00', '0', nil, '7654.0']
      ])
    end

    it 'should filter the results by campaign' do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      campaign2 = create(:campaign, company: company, name: 'Campaign not included')
      campaign2.assign_all_global_kpis

      event1 = create(:approved_event, campaign: campaign,
                                       start_date: '01/23/2013', end_date: '01/23/2013')
      set_event_results(event1, impressions: 111)
      event2 = create(:approved_event, campaign: campaign2,
                                       start_date: '01/24/2013', end_date: '01/24/2013')
      set_event_results(event2, impressions: 222)

      Sunspot.commit

      expect { xhr :get, 'index', format: :csv, campaign: [campaign.id] }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END', 'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS',
         'SPENT', 'GENDER: FEMALE', 'GENDER: MALE', 'AGE: < 12', 'AGE: 12 – 17', 'AGE: 18 – 24',
         'AGE: 25 – 34', 'AGE: 35 – 44', 'AGE: 45 – 54', 'AGE: 55 – 64', 'AGE: 65+', 'ETHNICITY/RACE: ASIAN',
         'ETHNICITY/RACE: BLACK / AFRICAN AMERICAN', 'ETHNICITY/RACE: HISPANIC / LATINO',
         'ETHNICITY/RACE: NATIVE AMERICAN', 'ETHNICITY/RACE: WHITE', 'IMPRESSIONS',
         'INTERACTIONS', 'SAMPLES'],
        ['Test Campaign FY01', nil, nil, nil, '', nil, nil, nil, nil, 'Active', 'Approved', '', '',
         "http://test.host/events/#{event1.id}", '2013-01-23 10:00', '2013-01-23 12:00', nil, nil,
         '2.00', '0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0',
         '0.0', '0.0', '0.0', '0.0', '0.0', '111.0', nil, nil]
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

      event1 = build(:approved_event, company: company, campaign: campaign, start_date: '01/23/2013',
                                      end_date: '01/23/2013')
      event2 = build(:approved_event, company: company, campaign: campaign, start_date: '01/24/2013',
                                      end_date: '01/24/2013')
      expect do
        event1.result_for_kpi(kpi).value = { seg1.id => '63', seg2.id => '37' }
        expect(event1.save).to be_truthy

        event2.result_for_kpi(kpi).value = nil
        event2.result_for_kpi(another_kpi).value = 134
        expect(event2.save).to be_truthy
      end.to change(FormFieldResult, :count).by(3)

      Sunspot.commit

      expect { xhr :get, 'index', campaign: [campaign.id], format: :csv }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
         'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END',
         'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS', 'SPENT', 'MY KPI: UNO', 'MY KPI: DOS', 'MY OTHER KPI'],
        ['Test Campaign FY01', nil, nil, nil, '', nil, nil, nil, nil, 'Active', 'Approved', '', '',
         "http://test.host/events/#{event1.id}", '2013-01-23 10:00', '2013-01-23 12:00',
         nil, nil, '2.00', '0', '0.63', '0.37', nil],
        ['Test Campaign FY01', nil, nil, nil, '', nil, nil, nil, nil, 'Active', 'Approved', '', '',
         "http://test.host/events/#{event2.id}", '2013-01-24 10:00', '2013-01-24 12:00',
         nil, nil, '2.00', '0', '0.0', '0.0', '134.0']
      ])
    end

    describe 'Include the likert scale fields' do
      let(:cf) { create(:custom_filter, owner: company_user, filters: "campaign[]=#{campaign.id}") }
      let(:option1) { create(:form_field_option, name: 'LikertScale Opt1') }
      let(:option2) { create(:form_field_option, name: 'LikertScale Opt2') }
      let(:statement1) { create(:form_field_statement, name: 'LikertScale Stat1') }
      let(:statement2) { create(:form_field_statement, name: 'LikertScale Stat2') }
      let(:field) { create(:form_field_likert_scale, name: 'My LikertScale Field',
                                                     fieldable: campaign,
                                                     multiple: false,
                                                     options: [option1, option2],
                                                     statements: [statement1, statement2]
                    )
      }

      let(:place) { create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US') }
      let(:event) { build(:approved_event, campaign: campaign, place: place, start_date: '01/23/2013', end_date: '01/23/2013') }

      it 'should correctly include the single answer likert scale fields' do
        event.results_for([field]).first.value = { statement1.id.to_s => option1.id.to_s,
                                                   statement2.id.to_s => option2.id.to_s }
        event.save
        Sunspot.commit

        expect { xhr :get, 'index', cfid: [cf.id], format: :csv }.to change(ListExport, :count).by(1)
        ResqueSpec.perform_all(:export)
        expect(ListExport.last).to have_rows([
          ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
           'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END', 'SUBMITTED AT',
           'APPROVED AT', 'PROMO HOURS', 'SPENT', 'MY LIKERTSCALE FIELD: LIKERTSCALE OPT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE OPT2'],
          ['Test Campaign FY01', '', nil, 'Bar Prueba', 'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US',
           'Los Angeles', 'California', '12345', 'Active', 'Approved', '', '', "http://test.host/events/#{event.id}",
           '2013-01-23 10:00', '2013-01-23 12:00', nil, nil, '2.00', '0', 'LikertScale Stat1', 'LikertScale Stat2']
        ])
      end

      it 'should correctly include the multiple answer likert scale fields' do
        field.update_attribute(:multiple, true)
        event.results_for([field]).first.value = { statement1.id.to_s => [option1.id.to_s],
                                                   statement2.id.to_s => [option1.id.to_s, option2.id.to_s] }
        event.save
        Sunspot.commit

        expect { xhr :get, 'index', cfid: [cf.id], format: :csv }.to change(ListExport, :count).by(1)
        ResqueSpec.perform_all(:export)
        expect(ListExport.last).to have_rows([
          ['CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'CITY', 'STATE', 'ZIP',
           'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL', 'START', 'END', 'SUBMITTED AT',
           'APPROVED AT', 'PROMO HOURS', 'SPENT', 'MY LIKERTSCALE FIELD: LIKERTSCALE OPT1', 'MY LIKERTSCALE FIELD: LIKERTSCALE OPT2'],
          ['Test Campaign FY01', '', nil, 'Bar Prueba', 'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'US',
           'Los Angeles', 'California', '12345', 'Active', 'Approved', '', '', "http://test.host/events/#{event.id}",
           '2013-01-23 10:00', '2013-01-23 12:00', nil, nil, '2.00', '0', 'LikertScale Stat1, LikertScale Stat2', 'LikertScale Stat2']
        ])
      end
    end
  end
end
