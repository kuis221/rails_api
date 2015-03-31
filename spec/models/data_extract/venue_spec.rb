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

RSpec.describe DataExtract::Venue, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
        [:name, :venues_types, :street, :city, :state_name, :country_name,
        :zipcode, :td_linx_code, :created_at])
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
        create(:venue, place: create(:place, name: 'My Place'), company: company, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ["My Place", "---\n- establishment\n", "11 Main St.", "New York City", "NY", "US", "12345", nil, "08/23/2013"]
        ]
      end

      it 'allows to sort the results' do
        create(:venue, place: create(:place, name: 'Tres Rios', city: 'La Unión'), company: company, created_at: Time.zone.local(2014, 2, 12, 9, 15))
        
        subject.columns = ['name', 'city']
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["My Place", "New York City"], 
          ["Tres Rios", "La Unión"]
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Tres Rios", "La Unión"], 
          ["My Place", "New York City"]
        ]

        subject.default_sort_by = 'city'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Tres Rios", "La Unión"], 
          ["My Place", "New York City"]
        ]

        subject.default_sort_by = 'city'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["My Place", "New York City"], 
          ["Tres Rios", "La Unión"]
        ]
      end
    end
  end
end
