require 'spec_helper'

describe ContactEventsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:event){ FactoryGirl.create(:event, company: @company) }
  let(:contact){ FactoryGirl.create(:contact, first_name: @user.first_name, company: @company) }
  let(:company_user){ @company_user }
  let(:contact_event){ FactoryGirl.create(:contact_event, event: event, contactable: contact) }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', event_id: event.to_param, format: :js
      response.should be_success
      response.should render_template('new')
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', event_id: event.to_param, id: contact_event.id, format: :js
      assigns(:contact_event).should == contact_event
      response.should be_success
      response.should render_template('edit')
    end
  end

  describe "GET 'add'" do
    it "returns http success" do
      contact.reload
      get 'add', event_id: event.to_param, format: :js
      response.should be_success
      response.should render_template('add')
    end
  end

  describe "POST 'create'" do
    it "assigns the contact to the event" do
      expect {
        post 'create', event_id: event.to_param, contact_event: {contactable_id: contact.id, contactable_type: 'Contact'}, format: :js
        response.should be_success
      }.to change(ContactEvent, :count).by(1)
      c = ContactEvent.last
      c.contactable.should == contact
      c.event_id.should == event.id
    end

    it "loads the contact edit form if the contact record is invalid" do
      contact = Contact.new
      contact.save(validate: false).should be_truthy
      expect(contact.persisted?).to be_truthy
      expect {
        post 'create', event_id: event.to_param, contact_event: {contactable_id: contact.id, contactable_type: 'Contact'}, format: :js
        response.should be_success
        response.should render_template('contact_events/_form')
      }.to_not change(ContactEvent, :count)
    end

    it "assigns the company user to the event" do
      expect {
        post 'create', event_id: event.to_param, contact_event: {contactable_id: company_user.id, contactable_type: 'CompanyUser'}, format: :js
        response.should be_success
      }.to change(ContactEvent, :count).by(1)
      c = ContactEvent.last
      c.contactable.should == company_user
      c.event_id.should == event.id
    end

    it "adds the contact to the event saving the changes to an existing contact" do
      contact = FactoryGirl.create(:contact, company: @company)
      expect {
        expect {
          post 'create', event_id: event.to_param,  contact_event: {contactable_type: 'Contact', contactable_id: contact.id, contactable_attributes: {id: contact.id, first_name: 'Fulanito', last_name: 'De Tal', email: 'email@test.com', country: 'US', state: 'CA', city: 'Los Angeles', phone_number: '12345678', zip_code: '12345'}}, format: :js
          response.should be_success
        }.to_not change(Contact, :count)
      }.to change(ContactEvent, :count).by(1)

      contact.reload
      contact.first_name.should == 'Fulanito'
      contact.last_name.should == 'De Tal'
      contact.email.should == 'email@test.com'
      contact.phone_number.should == '12345678'
      contact.country.should == 'US'
      contact.state.should == 'CA'
      contact.city.should == 'Los Angeles'
      contact.zip_code.should == '12345'
    end

    it "creates a new contact and assigns it to the event" do
      expect {
        expect {
          post 'create', event_id: event.to_param, contact_event: {contactable_attributes: {first_name: 'Fulanito', last_name: 'De Tal', email: 'email@test.com', country: 'US', state: 'CA', city: 'Los Angeles', phone_number: '12345678', zip_code: '12345'}}, format: :js
          response.should be_success
        }.to change(Contact, :count).by(1)
      }.to change(ContactEvent, :count).by(1)

      c = Contact.last
      c.first_name.should == 'Fulanito'
      c.last_name.should == 'De Tal'
      c.email.should == 'email@test.com'
      c.phone_number.should == '12345678'
      c.country.should == 'US'
      c.state.should == 'CA'
      c.city.should == 'Los Angeles'
      c.zip_code.should == '12345'
    end
  end

  describe "PUT 'update'" do
    it "should correctly update the contact details" do
      contact_event.reload
      expect {
        expect {
          put 'update', event_id: event.to_param, id: contact_event.id, contact_event: {contactable_attributes: {id: contact_event.contactable.id, first_name: 'Fulanito', last_name: 'De Tal', email: 'email@test.com', country: 'US', state: 'CA', city: 'Los Angeles', phone_number: '12345678', zip_code: '12345'}}, format: :js
          response.should be_success
        }.to_not change(Contact, :count)
      }.to_not change(ContactEvent, :count)

      c = Contact.last
      c.first_name.should == 'Fulanito'
      c.last_name.should == 'De Tal'
      c.email.should == 'email@test.com'
      c.phone_number.should == '12345678'
      c.country.should == 'US'
      c.state.should == 'CA'
      c.city.should == 'Los Angeles'
      c.zip_code.should == '12345'
    end
  end

  describe "DELETE 'destroy'" do
    it "should remove the contact_event record from the database" do
      contact_event.reload
      expect {
        delete 'destroy', event_id: event.to_param, id: contact_event.to_param, format: :js
      }.to change(ContactEvent, :count).by(-1)
    end
  end
end
