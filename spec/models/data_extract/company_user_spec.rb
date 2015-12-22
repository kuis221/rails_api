# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
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

RSpec.describe DataExtract::CompanyUser, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        ['first_name', 'First Name'], ['last_name', 'Last Name'],
        %w(teams_name Teams), %w(email Email), ['phone_number', 'Phone Number'],
        %w(role_name Role), ['address1', 'Address 1'], ['address2', 'Address 2'],
        %w(country Country), %w(city City), %w(state State), ['zip_code', 'ZIP code'],
        ['time_zone', 'Time Zone'], ['created_at', 'Created At'],
        ['created_by', 'Created By'], ['modified_at', 'Modified At'],
        ['modified_by', 'Modified By'], ['active_state', 'Active State']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas',
                                                email: 'benito@gmail.com'))
    end

    let(:subject) do
      described_class.new(company: company, current_user: company_user,
                          columns: %w(first_name last_name teams_name email
                                      phone_number role_name address1 address2
                                      country city state zip_code time_zone
                                      created_at created_by modified_at
                                      modified_by active_state))
    end

    describe 'with data' do

      it 'returns all the events in the company with all the columns' do
        row = subject.rows.first
        expect(row[0]).to eql('Benito')
        expect(row[1]).to eql('Camelas')
        expect(row[2]).to eql('')
        expect(row[3]).to eql('benito@gmail.com')
        expect(row[4]).to eql('+1000000000')
        expect(row[6]).to eql('Street Address 123')
      end

      it 'allows to filter the results' do
        subject.filters = { 'role' => [company_user.role_id] }
        row = subject.rows.first
        expect(row[0]).to eql('Benito')
        expect(row[1]).to eql('Camelas')
        expect(row[2]).to eql('')
        expect(row[3]).to eql('benito@gmail.com')
        expect(row[4]).to eql('+1000000000')
        expect(row[6]).to eql('Street Address 123')

        subject.filters = { 'role' => [company_user.role_id + 1] }
        expect(subject.rows).to be_empty
      end
    end
  end
end
