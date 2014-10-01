require 'rails_helper'

describe ContactEventsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:event) { create(:event, company: @company) }
  let(:contact) { create(:contact, first_name: @user.first_name, company: @company) }
  let(:company_user) { @company_user }
  let(:contact_event) { create(:contact_event, event: event, contactable: contact) }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', event_id: event.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
    end
  end

  describe "GET 'edit'" do
    it 'returns http success' do
      xhr :get, 'edit', event_id: event.to_param, id: contact_event.id, format: :js
      expect(assigns(:contact_event)).to eq(contact_event)
      expect(response).to be_success
      expect(response).to render_template('edit')
    end
  end

  describe "GET 'add'" do
    it 'returns http success' do
      contact.reload
      xhr :get, 'add', event_id: event.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('add')
    end
  end

  describe "POST 'create'" do
    it 'assigns the contact to the event' do
      expect do
        xhr :post, 'create', event_id: event.to_param, contact_event: { contactable_id: contact.id, contactable_type: 'Contact' }, format: :js
        expect(response).to be_success
      end.to change(ContactEvent, :count).by(1)
      c = ContactEvent.last
      expect(c.contactable).to eq(contact)
      expect(c.event_id).to eq(event.id)
    end

    it 'loads the contact edit form if the contact record is invalid' do
      contact = Contact.new
      expect(contact.save(validate: false)).to be_truthy
      expect(contact.persisted?).to be_truthy
      expect do
        xhr :post, 'create', event_id: event.to_param, contact_event: { contactable_id: contact.id, contactable_type: 'Contact' }, format: :js
        expect(response).to be_success
        expect(response).to render_template('contact_events/_form')
      end.to_not change(ContactEvent, :count)
    end

    it 'assigns the company user to the event' do
      expect do
        xhr :post, 'create', event_id: event.to_param, contact_event: { contactable_id: company_user.id, contactable_type: 'CompanyUser' }, format: :js
        expect(response).to be_success
      end.to change(ContactEvent, :count).by(1)
      c = ContactEvent.last
      expect(c.contactable).to eq(company_user)
      expect(c.event_id).to eq(event.id)
    end

    it 'adds the contact to the event saving the changes to an existing contact' do
      contact = create(:contact, company: @company)
      expect do
        expect do
          xhr :post, 'create', event_id: event.to_param,  contact_event: { contactable_type: 'Contact', contactable_id: contact.id, contactable_attributes: { id: contact.id, first_name: 'Fulanito', last_name: 'De Tal', email: 'email@test.com', country: 'US', state: 'CA', city: 'Los Angeles', phone_number: '12345678', zip_code: '12345' } }, format: :js
          expect(response).to be_success
        end.to_not change(Contact, :count)
      end.to change(ContactEvent, :count).by(1)

      contact.reload
      expect(contact.first_name).to eq('Fulanito')
      expect(contact.last_name).to eq('De Tal')
      expect(contact.email).to eq('email@test.com')
      expect(contact.phone_number).to eq('12345678')
      expect(contact.country).to eq('US')
      expect(contact.state).to eq('CA')
      expect(contact.city).to eq('Los Angeles')
      expect(contact.zip_code).to eq('12345')
    end

    it 'creates a new contact and assigns it to the event' do
      expect do
        expect do
          xhr :post, 'create', event_id: event.to_param, contact_event: { contactable_attributes: { first_name: 'Fulanito', last_name: 'De Tal', email: 'email@test.com', country: 'US', state: 'CA', city: 'Los Angeles', phone_number: '12345678', zip_code: '12345' } }, format: :js
          expect(response).to be_success
        end.to change(Contact, :count).by(1)
      end.to change(ContactEvent, :count).by(1)

      c = Contact.last
      expect(c.first_name).to eq('Fulanito')
      expect(c.last_name).to eq('De Tal')
      expect(c.email).to eq('email@test.com')
      expect(c.phone_number).to eq('12345678')
      expect(c.country).to eq('US')
      expect(c.state).to eq('CA')
      expect(c.city).to eq('Los Angeles')
      expect(c.zip_code).to eq('12345')
    end
  end

  describe "PUT 'update'" do
    it 'should correctly update the contact details' do
      contact_event.reload
      expect do
        expect do
          xhr :put, 'update', event_id: event.to_param, id: contact_event.id, contact_event: { contactable_attributes: { id: contact_event.contactable.id, first_name: 'Fulanito', last_name: 'De Tal', email: 'email@test.com', country: 'US', state: 'CA', city: 'Los Angeles', phone_number: '12345678', zip_code: '12345' } }, format: :js
          expect(response).to be_success
        end.to_not change(Contact, :count)
      end.to_not change(ContactEvent, :count)

      c = Contact.last
      expect(c.first_name).to eq('Fulanito')
      expect(c.last_name).to eq('De Tal')
      expect(c.email).to eq('email@test.com')
      expect(c.phone_number).to eq('12345678')
      expect(c.country).to eq('US')
      expect(c.state).to eq('CA')
      expect(c.city).to eq('Los Angeles')
      expect(c.zip_code).to eq('12345')
    end
  end

  describe "DELETE 'destroy'" do
    it 'should remove the contact_event record from the database' do
      contact_event.reload
      expect do
        delete 'destroy', event_id: event.to_param, id: contact_event.to_param, format: :js
      end.to change(ContactEvent, :count).by(-1)
    end
  end
end
