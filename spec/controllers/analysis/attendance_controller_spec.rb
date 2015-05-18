require 'rails_helper'

describe Analysis::AttendanceController, type: :controller do
  let(:user) { company_user.user }
  let(:company) { create(:company) }
  let(:role) { create(:non_admin_role, company: company) }
  let(:permissions) { [[:index_results, 'Activity']] }
  let(:company_user) { create(:company_user, company: company, role: role, permissions: permissions) }
  let(:place) { create(:place, city: 'Los Angeles', state: 'California', lonlat: 'POINT (-118.23994 34.017892)') }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:event) { without_current_user { create(:event, campaign: campaign, place: create(:place)) } }
  let(:area) { create(:area, company: company, places: [create(:state, name: 'California')]) }

  let(:neighborhood) do
    create(:neighborhood,
           name: 'Central City', city: 'Los Angeles', state: 'CA',
           geog: '0106000020E6100000010000000103000000010000001A00000050115685F9915DC0'\
                 '59ED13E8250241405CAACD219C915DC09ED42FF248034140A79C451190915DC0DF456'\
                 'FD284034140BD0A2FD488915DC04870AC0AE50441406A8059CF51915DC0032044BFB8'\
                 '0441407D78EEB616915DC0BFEE7854720441401D49B580EA905DC009CD2E0A4104414'\
                 '0E0E4369ABB905DC027299A0219044140A8FFE4F57E905DC010122129DE03414035CD'\
                 '750635905DC0D2F46B599A03414061AE19BBD58F5DC02D701A28230341409A7A4B0AB'\
                 'C8F5DC08E3F6AF20D034140FCE852A7958F5DC0DEF917DB0B0341405BFF6B886B8F5D'\
                 'C0B645A6E816034140BD5E8ECE498F5DC0BA80641B240341402789693B548F5DC06E7'\
                 'E201BA20241405569DEAA578F5DC04FF044FCEA01414007AC1247558F5DC0F9354E22'\
                 '0C0141401B864BC04F8F5DC00FD7AB3981004140B99B7E4D69905DC0AE4B070B7D004'\
                 '1404813F89969905DC019B57A64FE004140E323050169905DC0C3B5DA5C630141404C'\
                 '41BAD0AC905DC087C9053F67014140FE1706826A915DC0E854AA6D6B01414061B11A5'\
                 '3FD915DC04D90DE496701414050115685F9915DC059ED13E825024140')
  end

  before { company_user.campaigns << campaign }
  before { company_user.places << event.place }
  before { sign_in_as_user company_user }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to be_success
    end
  end

  describe 'GET map' do
    before { neighborhood }

    it 'returns http success' do
      xhr :get, :map, campaign_id: campaign.id, event_id: event.id, format: :js
      expect(response).to be_success
    end

    it 'loads the correct set of neighborhoods' do
      create(:invite, event: event, venue: create(:venue, company: company, place: place))

      xhr :get, :map, campaign_id: campaign.id, event_id: event.id, area_id: area.id, format: :js

      expect(assigns(:neighborhoods)).to match_array [neighborhood]
    end

    describe 'for market level campaigns' do
      before do
        campaign.update_attribute :modules, 'attendance' => { 'settings' => { 'attendance_display' => '2' } }
      end

      it 'loads the zip codes from Google API and stores it in DB' do
        expect_any_instance_of(Analysis::AttendanceController).to receive(:open).and_return(double(
          read: '{"results":[{"geometry":{"location":{"lat":"34.0187789203171","lng":"-118.259249420375"}}}]}'
        ))
        invite = create(:invite, area: area, event: event)
        invite.rsvps.create(zip_code: '90011', attended: false)
        invite.rsvps.create(zip_code: '90011', attended: true)
        xhr :get, :map, campaign_id: campaign.id, event_id: event.id, format: :js

        expect(assigns(:neighborhoods)).to match_array [neighborhood]
        result = assigns(:neighborhoods).first
        expect(result.attendees).to eql 1
        expect(result.invitations).to eql 2
      end
    end
  end

  describe "GET 'list_export'", search: true do
    before { neighborhood }

    it 'exports an empty book with the correct headers' do
      expect do
        xhr :get, 'index', campaign_id: campaign.id,
                           event_id: event.id, format: :xls
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['NEIGHBORHOOD', 'CITY', 'STATE', 'ATTENDEES', 'ACCOUNTS ATTENDED', 'INVITATIONS']])
    end

    it 'exports the list of neighborhoods for the selected campaign/event' do
      create(:invite, event: event, venue: create(:venue, company: company, place: place))

      expect do
        xhr :get, 'index', campaign_id: campaign.id, event_id: event.id, format: :xls
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['NEIGHBORHOOD', 'CITY', 'STATE', 'ATTENDEES', 'ACCOUNTS ATTENDED', 'INVITATIONS'],
        ["Central City", "Los Angeles", "CA", "1", "0", "1"]])
    end
  end
end
