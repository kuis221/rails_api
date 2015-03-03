require 'rails_helper'

describe Api::V1::InvitesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company) }
  let(:place) { create(:place) }
  let(:event) { create(:event, campaign: campaign, place: place) }

  before { set_api_authentication_headers user, company }

  describe "POST 'create'" do
    it 'should create the invitation from event' do
      expect do
        post 'create', event_id: event.to_param, invite: {
          invitees: '5', rsvps_count: '7',
          attendees: '10', place_reference: place.to_param }, format: :json
      end.to change(Invite, :count).by(1)
      invite = Invite.last
      expect(invite.invitees).to eq(5)
      expect(invite.rsvps_count).to eq(7)
      expect(invite.attendees).to eq(10)
      expect(invite.venue.place_id).to eq(place.id)
    end
  end

  describe "PUT 'update'" do
    let(:invite) { create(:invite, event: event, venue: event.venue) }

    it 'must deactivate the invite' do
      put 'update', event_id: event.id, id: invite.to_param,
                    invite: { active: 'false' }, format: :json
      expect(assigns(:invite)).to eq(invite)
      expect(response).to be_success
      invite.reload
      expect(invite.active).to eq(false)
    end
  end
end
