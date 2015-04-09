require 'rails_helper'

RSpec.describe InvitesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:event) { create(:event, company: company) }
  let(:place) { create(:place) }
  let(:area) { create(:area) }

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
end
