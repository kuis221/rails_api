# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#

require 'rails_helper'

RSpec.describe DataExtract::Contact, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
       [:first_name, :last_name, :title, :email, :phone_number, 
        :street1, :street2, :country, :state, :city, :zip_code, :created_at])
    end
  end

   describe '#rows' do
    let(:company) { create(:company) }
    let(:user) { create(:company_user, company: company) }

    let(:subject) { described_class.new(company: company, current_user: user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        brand = create(:contact, company: company, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ["Julian", "Guerra", "Bar Owner", "somecontact@email.com", "344-23333", "12th St.", "", "US", "CA", "Hollywood", "43212", "08/23/2013"]
        ]
      end

      it 'allows to sort the results' do
        create(:contact, first_name: 'Ana', last_name: 'Soto', email: 'ana_soto@email.com', company: company, created_at: Time.zone.local(2014, 2, 12, 9, 15))
        
        subject.columns = ['first_name', 'last_name', 'email']
        subject.default_sort_by = 'first_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Ana", "Soto", "ana_soto@email.com"], 
          ["Julian", "Guerra", "somecontact@email.com"]
        ]

        subject.default_sort_by = 'first_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Julian", "Guerra", "somecontact@email.com"], 
          ["Ana", "Soto", "ana_soto@email.com"]
        ]

        subject.default_sort_by = 'email'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Ana", "Soto", "ana_soto@email.com"], 
          ["Julian", "Guerra", "somecontact@email.com"]
        ]

        subject.default_sort_by = 'email'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Julian", "Guerra", "somecontact@email.com"], 
          ["Ana", "Soto", "ana_soto@email.com"]
        ]
      end
    end
  end
end