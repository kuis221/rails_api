# == Schema Information
#
# Table name: data_extracts
#
#  id            :integer          not null, primary key
#  type          :string(255)
#  company_id    :integer
#  active        :boolean
#  sharing       :string(255)
#  name          :string(255)
#  description   :text
#  filters       :text
#  columns       :text
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime
#  updated_at    :datetime
#

require 'rails_helper'

RSpec.describe DataExtract::CompanyUser, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
        [:first_name, :last_name, :teams_name, :email, :phone_number, :role_name,
        :street_address, :country, :state, :zip_code, :time_zone, :created_at])
    end
  end

  describe '#rows', search: true do
    let(:company) { create(:company) }
    let(:subject) { described_class.new(company: company) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        user = create(:user, company: company, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        create(:company_user, user: user, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        Sunspot.commit
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ["Test", "User", nil, "testuser2@brandscopic.com", "+1000000000", 
            "Role 3", "Street Address 123", "CR", "SJ", "90210", "Pacific Time (US & Canada)", Time.zone.local(2013, 8, 23, 9, 15)]
        ]
      end

      it 'allows to filter the results' do

        subject.filters = { email: ['testuser2@brandscopic.com'] }
        expect(subject.rows).to eql [
          ["Test", "User", nil, "testuser2@brandscopic.com", "+1000000000", 
            "Role 3", "Street Address 123", "CR", "SJ", "90210", "Pacific Time (US & Canada)", Time.zone.local(2013, 8, 23, 9, 15)]
        ]
      end
    end
  end
end