require 'rails_helper'

describe ContactEventsController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.index(@company_user)
  end

  let(:event) { create(:event, company: @company) }
  let(:contact) { create(:contact, first_name: @user.first_name, company: @company) }
  let(:company_user) { @company_user }

  describe "GET 'list'"do
    it 'returns http success' do
      contact.reload # force the creation of the contact
      Sunspot.commit
      xhr :get, 'list', event_id: event.to_param, term: @user.first_name, format: :js
      expect(response).to be_success
      expect(response).to render_template('list')

      expect(assigns(:contacts)).to match_array([company_user, contact])
    end

    it 'should not load in @contacts the contacts that are already assigned to the event' do
      create(:contact_event, event: event, contactable: contact)
      Sunspot.commit
      xhr :get, 'list', event_id: event.to_param, term: @user.first_name, format: :js
      expect(assigns(:contacts)).to match_array([company_user])
    end

    it 'should not load in @contacts the users that are already assigned to the event' do
      contact.reload
      create(:contact_event, event: event, contactable: company_user)
      Sunspot.commit
      xhr :get, 'list', event_id: event.to_param, term: @user.first_name, format: :js
      expect(assigns(:contacts)).to match_array([contact])
    end
  end
end
