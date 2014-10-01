# == Schema Information
#
# Table name: contact_events
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  contactable_id   :integer
#  contactable_type :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe ContactEvent, type: :model do
  it { is_expected.to belong_to(:contactable) }
  it { is_expected.to belong_to(:event) }

  describe '#title' do
    it "should return the contact's title" do
      contact_event = create(:contact_event, contactable: create(:contact, title: 'A sample title'))
      expect(contact_event.title).to eq('A sample title')
    end

    it "should return the user's role name" do
      contact_event = create(:contact_event, contactable: create(:company_user, role: create(:role, name: 'A sample role')))
      expect(contact_event.title).to eq('A sample role')
    end
  end

  describe '#street_address' do
    it 'should return both address1+address2 from the contact' do
      contact_event = create(:contact_event, contactable: create(:contact, street1: 'some street', street2: '2nd floor'))
      expect(contact_event.street_address).to eq('some street, 2nd floor')
    end

    it 'should return the street_address from the user' do
      contact_event = create(:contact_event, contactable: create(:company_user, user: create(:user, street_address: 'this is the street address')))
      expect(contact_event.street_address).to eq('this is the street address')
    end
  end

  describe '#build_contactable' do
    it 'should build a new contact' do
      contact_event = ContactEvent.new
      expect(contact_event.contactable).to be_nil
      contact_event.build_contactable
      expect(contact_event.contactable).to be_a(Contact)
      expect(contact_event.contactable.new_record?).to be_truthy
    end
  end
end
