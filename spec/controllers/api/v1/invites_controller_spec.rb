require 'rails_helper'

describe Api::V1::InvitesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  before { set_api_authentication_headers user, company }


  describe "PUT 'update'" do
    let(:campaign) { create(:campaign, company: company) }
    let(:event) { create(:event, company: company, campaign: campaign) }
    let(:venue) { create(:venue, company: company) }
    let(:invite) { create(:invite, event: event, venue: venue) }


    it 'must deactivate the invite' do
      put 'update', event_id: event.id, id: invite.to_param, invite: { active: 'false' }, format: :json
      expect(assigns(:invite)).to eq(invite)
      expect(response).to be_success
      invite.reload
      expect(invite.active).to eq(false)
    end
  end
end
