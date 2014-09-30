# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  company_id   :integer
#  first_name   :string(255)
#  last_name    :string(255)
#  title        :string(255)
#  email        :string(255)
#  phone_number :string(255)
#  street1      :string(255)
#  street2      :string(255)
#  country      :string(255)
#  state        :string(255)
#  city         :string(255)
#  zip_code     :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

describe Contact, type: :model do
  it { is_expected.to have_many(:contact_events) }
  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_presence_of(:city) }

  it { is_expected.to allow_value('guilleva@gmail.com').for(:email) }
  it { is_expected.to allow_value('').for(:email) }
  it { is_expected.to allow_value(nil).for(:email) }
  it { is_expected.not_to allow_value('guilleva').for(:email) }
  it { is_expected.not_to allow_value('guilleva@dsada').for(:email) }

  it { is_expected.to allow_value('US').for(:country) }
  it { is_expected.to allow_value('CR').for(:country) }
  it { is_expected.to allow_value('CA').for(:country) }
  it { is_expected.not_to allow_value('ZZY').for(:country).with_message('is not valid') }
  it { is_expected.not_to allow_value('Costa Rica').for(:country).with_message('is not valid') }
  it { is_expected.not_to allow_value('United States').for(:country).with_message('is not valid') }

  describe 'state validation' do
    describe 'with United States as country' do
      subject { Contact.new(country: 'US') }

      it { is_expected.to allow_value('CA').for(:state) }
      it { is_expected.not_to allow_value('ON').for(:state).with_message('is not valid') }
    end
  end

  describe '#full_name' do
    let(:contact) { build(:contact, first_name: 'Juanito', last_name: 'Perez') }

    it 'should return the first_name and last_name concatenated' do
      expect(contact.full_name).to eq('Juanito Perez')
    end

    it "should return only the first_name if it doesn't have last_name" do
      contact.last_name = nil
      expect(contact.full_name).to eq('Juanito')
    end

    it "should return only the last_name if it doesn't have first_name" do
      contact.first_name = nil
      expect(contact.full_name).to eq('Perez')
    end
  end

  describe '#country_name' do
    it 'should return the correct country name' do
      contact = build(:contact, country: 'US')
      expect(contact.country_name).to eq('United States')
    end

    it "should return nil if the contact doesn't have a country" do
      contact = build(:contact, country: nil)
      expect(contact.country_name).to be_nil
    end

    it 'should return nil if the contact has an invalid country' do
      contact = build(:contact, country: 'XYZ')
      expect(contact.country_name).to be_nil
    end
  end

  describe '#street_address' do
    it 'should return both address1+address2' do
      contact = build(:contact, street1: 'some street', street2: '2nd floor')
      expect(contact.street_address).to eq('some street, 2nd floor')
    end

    it 'should return only address1+address2' do
      contact = build(:contact, street1: 'some street', street2: '')
      expect(contact.street_address).to eq('some street')
    end
  end
end
