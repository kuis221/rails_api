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

require 'spec_helper'

describe ContactEvent do
  it { should belong_to(:contactable) }
  it { should belong_to(:event) }

  describe "#title" do
    it "should return the contact's title" do
      contact_event = FactoryGirl.create(:contact_event, contactable: FactoryGirl.create(:contact, title: 'A sample title'))
      contact_event.title.should == 'A sample title'
    end

    it "should return the user's role name" do
      contact_event = FactoryGirl.create(:contact_event, contactable: FactoryGirl.create(:company_user, role: FactoryGirl.create(:role, name: 'A sample role')))
      contact_event.title.should == 'A sample role'
    end
  end

  describe "#street_address" do
    it "should return both address1+address2 from the contact" do
      contact_event = FactoryGirl.create(:contact_event, contactable: FactoryGirl.create(:contact, street1: 'some street', street2: '2nd floor'))
      contact_event.street_address.should == 'some street, 2nd floor'
    end

    it "should return the street_address from the user" do
      contact_event = FactoryGirl.create(:contact_event, contactable: FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, street_address: 'this is the street address')))
      contact_event.street_address.should == 'this is the street address'
    end
  end

  describe "#build_contactable" do
    it "should build a new contact" do
      contact_event = ContactEvent.new
      contact_event.contactable.should be_nil
      contact_event.build_contactable
      contact_event.contactable.should be_a(Contact)
      contact_event.contactable.new_record?.should be_truthy
    end
  end
end
