require 'rails_helper'

RSpec.describe InvitesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:event) { create(:event, company: company) }
  let(:place) { create(:place, name: 'My Super Place') }
  let(:area) { create(:area, name: 'California', company: company) }
  let(:venue) { create(:venue, place: place, company: company) }

  before { user }

  describe "POST 'create'" do
    describe 'inviting a business' do
      it 'creates the invitation' do
        expect do
          xhr :post, 'create', event_id: event.id, invite: {
            place_reference: place.id.to_s,
            invitees: 100
          }, format: :js
        end.to change(Invite, :count).by(1)
        expect(response).to render_template 'create'
      end

      it 'increases the invitees counter if there is an invitation for the venue' do
        invite = create :invite, venue: venue, invitees: 10, event: event
        expect do
          xhr :post, 'create', event_id: event.id, invite: {
            place_reference: place.id.to_s, invitees: 3
          }, format: :js
        end.to_not change(Invite, :count)
        expect(invite.reload.invitees).to eql 13
        expect(response).to render_template 'create'
      end

      it 'renders the form_dialog template if errors' do
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
    end
  end

  describe "GET 'list_export'", :search, :inline_jobs do
    let(:campaign) { create(:campaign, name: 'Test Campaign FY01', company: company, modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '1' } } }) }
    let(:event) { create(:event, campaign: campaign, start_date: '01/01/2015', end_date: '01/01/2015') }

    describe 'for a event' do
      it 'generates empty csv with the correct headers' do
        expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES']
        ])
      end

      it 'includes the invites individual information' do
        invite = create(:invite, event: event, invitees: 100, attendees: 2, rsvps_count: 99)
        expect { xhr :get, 'index', event_id: event.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES'],
          ['Place 1', '2015-01-01 10:00', 'Test Campaign FY01', "100", "99", "2"]
        ])
      end
    end

    describe 'for a venue' do
      it 'generates empty csv with the correct headers when exporting invites for a venue' do
        expect { xhr :get, 'index', venue_id: venue.id, format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ])
      end

      it 'includes the invites when exporting invites for a venue' do
        invite = create(:invite, event: event, venue: venue, invitees: 100, attendees: 2, rsvps_count: 99)
        expect { xhr :get, 'index', venue_id: venue.id, format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES'],
          ['My Super Place', '2015-01-01 10:00', 'Test Campaign FY01', "100", "99", "2"]
        ])
      end
    end

  end
end
