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

RSpec.describe DataExtract::Area, type: :model do
  pending '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
       [:name, :description, :created_by_full_name, :created_at])
    end
  end

  pending '#rows', search: true do
    let(:company) { create(:company) }
    let(:subject) { described_class.new(company: company) }
    let(:company_user) { create(:company_user, company: company,
                         user: create(:user, first_name: 'Benito', last_name: 'Camelas')) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica',
                 active: true, company: company, created_by_id: company_user.user.id, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        Sunspot.commit
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Zona Norte', 'Ciudades del Norte de Costa Rica', 'Benito Camelas', Time.zone.local(2013, 8, 23, 9, 15)]
        ]
      end

      it 'allows to filter the results' do

        subject.filters = { name: ['Zona Norte'] }
        expect(subject.rows).to eql [
          ['Zona Norte', 'Ciudades del Norte de Costa Rica', 'Benito Camelas', Time.zone.local(2013, 8, 23, 9, 15)]
        ]
      end
    end
  end
end
