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

RSpec.describe DataExtract::CompanyUser, type: :model do
  pending '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
        [:first_name, :last_name, :teams_name, :email, :phone_number, :role_name,
         :street_address, :country, :city, :state, :zip_code, :time_zone, :created_at,
         :created_by, :modified_at, :modified_by, :active_state])
    end
  end

  pending '#rows' do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company,
                        user: create(:user, first_name: 'Benito', last_name: 'Camelas')) }

    let(:subject) { described_class.new() }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        user = create(:user, company: company, email: 'testuser2@brandscopic.com')
        create(:company_user, user: user)
        Sunspot.commit
      end

      it 'returns all the events in the company with all the columns' do
        row = subject.rows.first
        expect(row[0]).to eql('Test')
        expect(row[1]).to eql('User')
        expect(row[2]).to eql('')
        expect(row[3]).to eql('testuser2@brandscopic.com')
        expect(row[4]).to eql('+1000000000')
        expect(row[6]).to eql('Street Address 123')
      end

      it 'allows to filter the results' do
        subject.filters = { email: ['testuser2@brandscopic.com'] }
        row = subject.rows.first
        expect(row[0]).to eql('Test')
        expect(row[1]).to eql('User')
        expect(row[2]).to eql('')
        expect(row[3]).to eql('testuser2@brandscopic.com')
        expect(row[4]).to eql('+1000000000')
        expect(row[6]).to eql('Street Address 123')
      end
    end
  end
end
