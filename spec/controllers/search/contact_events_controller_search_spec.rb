require 'spec_helper'

describe ContactEventsController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.index(@company_user)
  end

  let(:event){ FactoryGirl.create(:event, company: @company) }
  let(:contact){ FactoryGirl.create(:contact, first_name: @user.first_name, company: @company) }
  let(:company_user){ @company_user }

  describe "GET 'list'"do
    it "returns http success" do
      contact.reload # force the creation of the contact
      Sunspot.commit
      get 'list', event_id: event.to_param, term: @user.first_name, format: :js
      response.should be_success
      response.should render_template('list')

      assigns(:contacts).should =~ [company_user, contact]
    end

    it "should not load in @contacts the contacts that are already assigned to the event" do
      FactoryGirl.create(:contact_event, event: event, contactable: contact)
      Sunspot.commit
      get 'list', event_id: event.to_param, term: @user.first_name, format: :js
      assigns(:contacts).should =~ [company_user]
    end

    it "should not load in @contacts the users that are already assigned to the event" do
      contact.reload
      FactoryGirl.create(:contact_event, event: event, contactable: company_user)
      Sunspot.commit
      get 'list', event_id: event.to_param, term: @user.first_name, format: :js
      assigns(:contacts).should =~ [contact]
    end
  end
end