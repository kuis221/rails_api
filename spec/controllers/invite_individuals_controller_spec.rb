require 'rails_helper'

RSpec.describe InviteIndividualsController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:event) { create(:event, company: company) }
  let(:place) { create(:place, name: 'My Super Place') }
  let(:area) { create(:area, name: 'California', company: company) }
  let(:venue) { create(:venue, place: place, jameson_locals: true) }

  before { user }

  describe "POST 'create'" do
    it 'creates the invitation' do
      expect do
        expect do
          xhr :post, 'create', event_id: event.id, invite_individual: {
            first_name: 'Luis', last_name: 'Perez', email: 'lp@test.com',
            invite_attributes: { place_reference: place.id.to_s },
          }, format: :js
        end.to change(Invite, :count).by(1)
      end.to change(InviteIndividual, :count).by(1)
      invite = Invite.last
      expect(invite.invitees).to eql 1
      expect(response).to render_template 'create'
    end

    it 'increases the invitees counter if there is an invitation for the venue' do
      invite = create :invite, place: place, invitees: 10, event: event
      expect do
        expect do
          xhr :post, 'create', event_id: event.id, invite_individual: {
            first_name: 'Luis', last_name: 'Perez', email: 'lp@test.com',
            invite_attributes: { place_reference: place.id.to_s },
          }, format: :js
        end.to_not change(Invite, :count)
      end.to change(InviteIndividual, :count).by(1)
      expect(invite.reload.invitees).to eql 11
      expect(response).to render_template 'create'
    end

    it 'renders the form_dialog template if errors' do
      expect do
        xhr :post, 'create', event_id: event.id, invite_individual: {
          first_name: 'Luis', last_name: 'Perez', email: 'lp@test.com',
          invite_attributes: { place_reference: nil },
        }, format: :js
      end.not_to change(Invite, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:invite_individual).errors.count).to be > 0
    end
  end

  describe "GET 'list_export'", :search, :inline_jobs do
    let(:campaign) { create(:campaign, name: 'Test Campaign FY01', company: company, modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '1' } } }) }
    let(:event) { create(:event, campaign: campaign, start_date: '01/01/2015', end_date: '01/01/2015') }

    describe 'for a event' do
      it 'generates empty csv with the correct headers' do
        expect { xhr :get, 'index', event_id: event.id, format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'NAME', 'EMAIL', 'RSVP\'d', 'ATTENDED']
        ])
      end

      it 'includes the invites individual information' do
        invite = create(:invite, event: event, invitees: 100, attendees: 2, rsvps_count: 99)
        create(:invite_individual, invite: invite)
        create(:invite_individual, invite: invite)
        expect { xhr :get, 'index', event_id: event.id, export_mode: 'individual', format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'NAME', 'EMAIL', 'RSVP\'d', 'ATTENDED'],
          ['Place 1', '2015-01-01 10:00', 'Test Campaign FY01', 'Fulano de Tal', 'rsvp@email.com', 'NO', 'NO'],
          ['Place 1', '2015-01-01 10:00', 'Test Campaign FY01', 'Fulano de Tal', 'rsvp@email.com', 'NO', 'NO']
        ])
      end
    end


    describe 'for a venue' do
      it 'generates empty csv with the correct headers when exporting invites for a venue' do
        expect { xhr :get, 'index', venue_id: venue.id, format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'NAME', 'EMAIL', 'RSVP\'d', 'ATTENDED']
        ])
      end

      it 'includes the invites when exporting invites for a venue' do
        invite = create(:invite, event: event, venue: venue, invitees: 100, attendees: 2, rsvps_count: 99)
        create(:invite_individual, invite: invite)
        create(:invite_individual, invite: invite)
        expect { xhr :get, 'index', venue_id: venue.id, format: :csv }.to change(ListExport, :count).by(1)

        expect(ListExport.last).to have_rows([
          ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'NAME', 'EMAIL', 'RSVP\'d', 'ATTENDED'],
          ['My Super Place', '2015-01-01 10:00', 'Test Campaign FY01', 'Fulano de Tal', 'rsvp@email.com', 'NO', 'NO'],
          ['My Super Place', '2015-01-01 10:00', 'Test Campaign FY01', 'Fulano de Tal', 'rsvp@email.com', 'NO', 'NO']
        ])
      end
    end

  end
end
