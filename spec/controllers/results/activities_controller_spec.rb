require 'rails_helper'

describe Results::ActivitiesController, type: :controller do
  let(:user) { company_user.user }
  let(:company) { create(:company) }
  let(:role) { create(:non_admin_role, company: company) }
  let(:permissions) { [[:index_results, 'Activity']] }
  let(:company_user) { create(:company_user, company: company, role: role, permissions: permissions) }

  before { sign_in_as_user company_user }

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'returns http success on html format' do
      get 'items'
      expect(response).to be_success
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
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:place) do
      create(:place, name: 'Bar Prueba', city: 'Los Angeles',
                     state: 'California', country: 'US', td_linx_code: '443321')
    end
    let(:event) { create(:event, campaign: campaign, place: place) }
    let(:activity_type) { create(:activity_type, name: 'My Activity Type', campaign_ids: [campaign.id], company: company) }
    let(:event_activity) do
      without_current_user do
        create(:activity, activitable: event, activity_date: '01/01/2014',
          campaign: campaign, created_at: DateTime.parse('2015-07-01 02:11 -07:00'),
          updated_at: DateTime.parse('2015-07-03 02:11 -07:00'), activity_type: activity_type, company_user: company_user)
      end
    end

    before { company_user.campaigns << campaign }

    it 'return an empty book with the correct headers' do
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
         'ADDRESS', 'CITY', 'STATE', 'ZIP', 'COUNTRY', 'ACTIVE STATE', 'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY']
      ])
    end

    it 'should include the event data results' do
      area = create(:area, name: 'My area', company: company)
      area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      company_user.areas << area
      campaign.areas << area

      field = create(:form_field_number, name: 'My Numeric Field', fieldable: activity_type)

      event_activity.results_for([field]).first.value = 123
      event_activity.save

      Sunspot.commit

      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
         'ADDRESS', 'CITY', 'STATE', 'ZIP', 'COUNTRY', 'ACTIVE STATE', 'CREATED AT', 'CREATED BY', 'LAST MODIFIED',
         'MODIFIED BY', 'MY NUMERIC FIELD'],
        ['Test Campaign FY01', user.full_name, '2014-01-01', 'My Activity Type', 'My area',
         '="443321"', 'Bar Prueba', 'Bar Prueba, 11 Main St., Los Angeles, California, 12345', 'Los Angeles',
         'California', '12345', 'US', 'Active', '2015-07-01 02:11', nil, '2015-07-03 02:11', 'Test User', '123.0']
      ])

    end

    describe 'custom fields' do
      before do
        create(:form_field_checkbox,
               name: 'My Chk Field', fieldable: activity_type, options: [
                 create(:form_field_option, name: 'Chk Opt1'),
                 create(:form_field_option, name: 'Chk Opt2')])

        other_campaign = create(:campaign, company: company, name: 'Other Campaign FY01')
        other_activity_type = create(:activity_type, company: company, campaign_ids: [other_campaign.id])
        create(:form_field_radio,
               name: 'My Radio Field', fieldable: other_activity_type, options: [
                 create(:form_field_option, name: 'Radio Opt1'),
                 create(:form_field_option, name: 'Radio Opt2')])
        company_user.campaigns << other_campaign
      end

      it 'should include the activity data results only for the given campaign' do
        expect { xhr :get, 'index', campaign: [campaign.id], format: :csv }.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        expect(export.reload).to have_rows([
          ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
           'ADDRESS', 'CITY', 'STATE', 'ZIP', 'COUNTRY', 'ACTIVE STATE', 'CREATED AT', 'CREATED BY', 'LAST MODIFIED',
           'MODIFIED BY', 'MY CHK FIELD: CHK OPT1', 'MY CHK FIELD: CHK OPT2']
        ])
      end

      it 'should include any custom kpis from all the campaigns' do
        expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        expect(export.reload).to have_rows([
          ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
           'ADDRESS', 'CITY', 'STATE', 'ZIP', 'COUNTRY', 'ACTIVE STATE', 'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY',
           'MY CHK FIELD: CHK OPT1', 'MY CHK FIELD: CHK OPT2', 'MY RADIO FIELD']
        ])
      end
    end
  end
end
