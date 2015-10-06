# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default(TRUE)
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

require 'rails_helper'

RSpec.describe DataExtract::Contact, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
        [['first_name', 'First Name'], ['last_name', 'Last Name'], %w(title Title), %w(email Email),
         ['phone_number', 'Phone Number'], %w(street1 Address), ['street2', 'Address 2'],
         %w(country Country), %w(state State), %w(city City), ['zip_code', 'ZIP code'],
         ['created_at', 'Created At'], ['created_by', 'Created By'], ['modified_at', 'Modified At'],
         ['modified_by', 'Modified By']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end

    let(:subject) do
      described_class.new(company: company, current_user: company_user,
                    columns: %w(first_name last_name title email p        hone_number street1 street2 country state city zip_code created_by created_at))
    end

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      let(:contact) do
        create(:contact, first_name: 'Julian', last_name: 'Guerra',
                         company: company, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        contact
        expect(subject.rows).to eql [
          [contact.first_name, contact.last_name, contact.title, contact.email, contact.phone_number,
           contact.street_address, '', 'US', contact.state, contact.city, contact.zip_code,
           nil, '08/23/2013']
        ]
      end

      it 'allows to sort the results' do
        contact
        create(:contact, first_name: 'Ana', last_name: 'Soto', email: 'ana_soto@email.com', company: company,
                         created_at: Time.zone.local(2014, 2, 12, 9, 15))
        create(:contact, first_name: 'Mariela', last_name: 'Castro', email: 'mariela_castro@email.com', company: company,
                         created_at: Time.zone.local(2015, 2, 12, 9, 15))

        subject.columns = %w(first_name last_name email, created_at)
        subject.default_sort_by = 'first_name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Ana', 'Soto', '02/12/2014'],
          ['Julian', 'Guerra', '08/23/2013'],
          ['Mariela', 'Castro', '02/12/2015']
        ]

        subject.default_sort_by = 'first_name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Mariela', 'Castro', '02/12/2015'],
          ['Julian', 'Guerra', '08/23/2013'],
          ['Ana', 'Soto', '02/12/2014']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Julian', 'Guerra', '08/23/2013'],
          ['Ana', 'Soto', '02/12/2014'],
          ['Mariela', 'Castro', '02/12/2015']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Mariela', 'Castro', '02/12/2015'],
          ['Ana', 'Soto', '02/12/2014'],
          ['Julian', 'Guerra', '08/23/2013']
        ]
      end
    end
  end
end
