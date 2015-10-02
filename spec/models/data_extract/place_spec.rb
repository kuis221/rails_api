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

RSpec.describe DataExtract::Place, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(name Name), %w(venues_types Types), ['street', 'Venue Street'], %w(city City),
        %w(state_name State), %w(country_name Country), %w(score Score), ['zipcode', 'ZIP code'],
        ['td_linx_code', 'TD Linx Code'], ['created_at', 'Created At'], ['created_by', 'Created By'],
        ['modified_at', 'Modified At'], ['modified_by', 'Modified By']])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:subject) do
      described_class.new(company: company,
        current_user: company_user,
        columns: ['name', 'venues_types', 'street', 'city', 'state_name', 'country_name',
                  'zipcode', 'td_linx_code', 'created_by', 'created_at'])
    end

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      let(:place1) do
        create(:place, name: 'Vertigo 42',
                       reference: 'REFERENCE1',
                       place_id: 'PLACEID1',
                       formatted_address: 'Tower 42, Los Angeles, CA 23211, United States',
                       street_number: 23, route: 'Main Street',
                       city: 'Los Angeles', state: 'CA', country: 'US',
                       lonlat: 'POINT(44.44 11.11)')
      end

      before do
        create(:venue, place: place1, company: company, created_at: Time.zone.local(2013, 8, 23, 9, 15))
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ['Vertigo 42', 'Establishment', '23 Main Street', 'Los Angeles', 'CA', 'US', '12345', nil, nil, '08/23/2013']
        ]
      end

      it 'allows to sort the results' do
        create(:venue, place: create(:place, name: 'Tres Rios', city: 'La Unión'), company: company, created_at: Time.zone.local(2014, 2, 12, 9, 15))

        subject.columns = %w(name city)
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Tres Rios', 'La Unión'],
          ['Vertigo 42', 'Los Angeles']
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Vertigo 42', 'Los Angeles'],
          ['Tres Rios', 'La Unión']
        ]

        subject.default_sort_by = 'city'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ['Tres Rios', 'La Unión'],
          ['Vertigo 42', 'Los Angeles']
        ]

        subject.default_sort_by = 'city'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ['Vertigo 42', 'Los Angeles'],
          ['Tres Rios', 'La Unión']
        ]
      end

      it 'returns the correct data avoiding merged venues' do
        place2 = create(:place, name: 'Vertigo Copy 42',
                                reference: 'REFERENCE3',
                                place_id: 'PLACEID2',
                                formatted_address: 'Tower 42 Copy, Los Angeles, CA 23211, United States',
                                street_number: 23, route: 'Main St.',
                                city: 'Los Angeles', state: 'CA', country: 'US',
                                lonlat: 'POINT(44.44 11.11)',
                                merged_with_place_id: place1.id)

        create(:venue, place: place2, company: company)

        expect(subject.rows).to eql [
          ['Vertigo 42', 'Establishment', '23 Main Street', 'Los Angeles', 'CA', 'US', '12345', nil, nil, '08/23/2013']
        ]
      end
    end
  end
end
