require 'rails_helper'

RSpec.describe InvitesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:event) { create(:event, company: company) }
  let(:place) { create(:place, name: 'My Super Place') }
  let(:area) { create(:area, name: 'California', company: company) }
  let(:venue) { create(:venue, place: place, jameson_locals: true) }

  before { user }

  describe "POST 'create'" do
    it 'when invite is a Venue, should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', event_id: event.id, invite: {
          place_reference: place.id.to_s,
          invitees: 100
        }, format: :js
      end.to change(Invite, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'when invite is a Market, should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', event_id: event.id, invite: {
          area_id: area.id.to_s,
          invitees: 100
        }, format: :js
      end.to change(Invite, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'when invite is a Venue, should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', event_id: event.id, invite: {
          place_reference: nil,
          invitees: 100
        }, format: :js
      end.not_to change(Invite, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:invite).errors.count).to be > 0
    end

    it 'when invite is a Market, should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', event_id: event.id, invite: {
          area_id: nil,
          invitees: 100
        }, format: :js
      end.not_to change(Invite, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:invite).errors.count).to be > 0
    end
  end

  describe "GET 'list_export'", search: true do
    let(:campaign) { create(:campaign, name: 'Test Campaign FY01', company: company, modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '1' } } }) }
    let(:event) { create(:event, campaign: campaign, start_date: '01/01/2015', end_date: '01/01/2015') }

    it 'for account level, generates empty csv with the correct headers' do
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES']
      ])
    end

    it 'for market level and aggregate mode, generates empty csv with the correct headers' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES']
      ])
    end

    it 'for market level and individual mode, generates an empty csv with the correct headers' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })
      expect { xhr :get, 'index', event_id: event.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES',
         'REGISTRANT ID', 'DATE ADDED', 'EMAIL', 'MOBILE PHONE', 'MOBILE SIGN UP', 'FIRST NAME', 'LAST NAME',
         'ATTENDED PREVIOUS BARTENDER BALL', 'OPT IN TO FUTURE COMMUNICATION', 'PRIMARY REGISTRANT ID',
         'BARTENDER HOW LONG', 'BARTENDER ROLE', 'DATE OF BIRTH', 'ZIP CODE']
      ])
    end

    it 'for account level, generates an empty csv with the correct headers' do
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES']
      ])
    end

    it 'generates empty csv with the correct headers when exporting invites for a venue' do
      expect { xhr :get, 'index', venue_id: venue.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES']
      ])
    end

    it 'for market level, includes the invites in aggregate mode' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })
      create(:invite, event: event, area: area, invitees: 100, attendees: 2, rsvps_count: 99)
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['California', '100', '99', '2']
      ])
    end

    it 'for market level, includes the invites and rsvps information in individual mode when exporting from event details' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })
      invite = create(:invite, event: event, area: area, invitees: 100, attendees: 2, rsvps_count: 99)
      create(:invite_rsvp, invite: invite)
      create(:invite_rsvp, invite: invite)
      expect { xhr :get, 'index', event_id: event.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES',
         'REGISTRANT ID', 'DATE ADDED', 'EMAIL', 'MOBILE PHONE', 'MOBILE SIGN UP', 'FIRST NAME', 'LAST NAME',
         'ATTENDED PREVIOUS BARTENDER BALL', 'OPT IN TO FUTURE COMMUNICATION', 'PRIMARY REGISTRANT ID',
         'BARTENDER HOW LONG', 'BARTENDER ROLE', 'DATE OF BIRTH', 'ZIP CODE'],
        ['California', '100', '99', '2', '1',
         '01/06/2015', 'rsvp@email.com', '123456789', 'NO', 'Fulano', 'de Tal', 'no', 'NO', '1', '2 years', 'Main', '3/2/1977', '90210'],
        ['California', '100', '99', '2', '1', '01/06/2015', 'rsvp@email.com', '123456789', 'NO',
         'Fulano', 'de Tal', 'no', 'NO', '1', '2 years', 'Main', '3/2/1977', '90210']
      ])
    end

    it 'for account level, includes the invites when exporting from event details' do
      create(:invite, event: event, venue: venue, invitees: 100, attendees: 2, rsvps_count: 99)
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['My Super Place', 'YES', 'NO', '100', '99', '2']
      ])
    end

    it 'includes the invites when exporting invites for a venue' do
      create(:invite, event: event, venue: venue, invitees: 100, attendees: 2, rsvps_count: 99)
      expect { xhr :get, 'index', venue_id: venue.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['2015-01-01 10:00', 'Test Campaign FY01', '100', '99', '2']
      ])
    end
  end
end
