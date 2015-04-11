require 'rails_helper'

RSpec.describe InvitesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:event) { create(:event, company: company) }
  let(:place) { create(:place, name: 'My Super Place') }
  let(:area) { create(:area) }
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
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:event) { create(:event, campaign: campaign, start_date: '01/01/2015', end_date: '01/01/2015') }

    it 'generates empty csv with the correct headers' do
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES']
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

    it 'includes the invites in aggregate mode' do
      venue2 = create(:venue, company: company)
      create(:invite, event: event, venue: venue, market: 'My Market', invitees: 100, attendees: 2, rsvps_count: 99)
      create(:invite, event: event, venue: venue2, market: 'My Market', invitees: 100, attendees: 2, rsvps_count: 99)
      create(:invite, event: event, venue: venue2, market: 'Market 2', invitees: 100, attendees: 2, rsvps_count: 99)
      expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['Market 2', '100', '99', '2'],
        ['My Market', '200', '198', '4']
      ])
    end

    it 'generates an empty csv with the correct headers for individual export' do
      expect { xhr :get, 'index', event_id: event.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES']
      ])
    end

    it 'includes the invites and rsvps information in individual mode when exporting from venue details' do
      invite = create(:invite, event: event, venue: venue, invitees: 100, attendees: 2, rsvps_count: 99)
      create(:invite_rsvp, invite: invite)
      expect { xhr :get, 'index', venue_id: venue.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['EVENT DATE', 'CAMPAIGN', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['2015-01-01 10:00', 'Test Campaign FY01', 'YES', 'NO', '100', '99', '2']
      ])
    end

    it 'includes the invites and rsvps information in individual mode when exporting from event details' do
      invite = create(:invite, event: event, venue: venue, invitees: 100, attendees: 2, rsvps_count: 99)
      create(:invite_rsvp, invite: invite)
      expect { xhr :get, 'index', event_id: event.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['My Super Place', 'YES', 'NO', '100', '99', '2']
      ])
    end
  end
end
