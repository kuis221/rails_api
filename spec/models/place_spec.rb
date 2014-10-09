# == Schema Information
#
# Table name: places
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  reference              :string(400)
#  place_id               :string(100)
#  types                  :string(255)
#  formatted_address      :string(255)
#  latitude               :float
#  longitude              :float
#  street_number          :string(255)
#  route                  :string(255)
#  zipcode                :string(255)
#  city                   :string(255)
#  state                  :string(255)
#  country                :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  administrative_level_1 :string(255)
#  administrative_level_2 :string(255)
#  td_linx_code           :string(255)
#  neighborhood           :string(255)
#  location_id            :integer
#  is_location            :boolean
#

require 'rails_helper'

describe Place, type: :model do

  it { is_expected.to validate_presence_of(:place_id) }
  it { is_expected.to validate_presence_of(:reference) }

  it { is_expected.to allow_value(nil).for(:country) }
  it { is_expected.to allow_value('').for(:country) }
  it { is_expected.to allow_value('US').for(:country) }
  it { is_expected.to allow_value('CR').for(:country) }
  it { is_expected.to allow_value('CA').for(:country) }
  it { is_expected.not_to allow_value('ZZY').for(:country).with_message('is not valid') }
  it { is_expected.not_to allow_value('Costa Rica').for(:country).with_message('is not valid') }
  it { is_expected.not_to allow_value('United States').for(:country).with_message('is not valid') }

  describe 'fetch_place_data' do
    it 'should correctly assign the attributes returned by the api call' do
      place = Place.new(reference: 'YXZ', place_id: '123')
      api_client = double(:google_places_client)
      expect(place).to receive(:client).at_least(:once).and_return(api_client)
      expect(api_client).to receive(:spot).with('YXZ').and_return(double(:spot, name: 'Rancho Grande',
                                                                                lat: '12.345678',
                                                                                lng: '-87.654321',
                                                                                formatted_address: '123 Mi Casa, Costa Rica',
                                                                                types: [1, 2, 3],
                                                                                address_components: [
                                                                                  { 'types' => ['country'], 'short_name' => 'CR', 'long_name' => 'Costa Rica' },
                                                                                  { 'types' => ['administrative_area_level_1'], 'short_name' => 'SJO', 'long_name' => 'San Jose' },
                                                                                  { 'types' => ['administrative_area_level_2'], 'short_name' => 'SJ2', 'long_name' => 'Example' },
                                                                                  { 'types' => ['locality'], 'short_name' => 'Curridabat', 'long_name' => 'Curridabat' },
                                                                                  { 'types' => ['postal_code'], 'short_name' => '12345', 'long_name' => '12345' },
                                                                                  { 'types' => ['street_number'], 'short_name' => '7', 'long_name' => '7' },
                                                                                  { 'types' => ['route'], 'short_name' => 'Calle Melancolia', 'long_name' => 'Calle Melancolia' }
                                                                                ]))
      expect(api_client).to receive(:spots).and_return([])

      place.save
      place.reload
      expect(place.name).to eq('Rancho Grande')
      expect(place.latitude).to eq(12.345678)
      expect(place.longitude).to eq(-87.654321)
      expect(place.formatted_address).to eq('123 Mi Casa, Costa Rica')
      expect(place.types).to eq([1, 2, 3])
      expect(place.country).to eq('CR')
      expect(place.city).to eq('Curridabat')
      expect(place.state).to eq('San Jose')
      expect(place.administrative_level_1).to eq('SJO')
      expect(place.administrative_level_2).to eq('SJ2')
      expect(place.zipcode).to eq('12345')
      expect(place.street_number).to eq('7')
      expect(place.route).to eq('Calle Melancolia')
    end

    it "should find out the correct state name if the API doesn't provide it" do
      place = Place.new(reference: 'YXZ', place_id: '123')
      api_client = double(:google_places_client)
      expect(place).to receive(:client).at_least(:once).and_return(api_client)
      expect(api_client).to receive(:spot).with('YXZ').and_return(double(:spot, name: 'Shark\'s Cove',
                                                                                lat: '12.345678',
                                                                                lng: '-87.654321',
                                                                                formatted_address: '123 Mi Casa, Costa Rica',
                                                                                types: [1, 2, 3],
                                                                                address_components: [
                                                                                  { 'types' => ['country'], 'short_name' => 'US', 'long_name' => 'United States' },
                                                                                  { 'types' => ['administrative_area_level_1'], 'short_name' => 'CA', 'long_name' => 'CA' },
                                                                                  { 'types' => ['locality'], 'short_name' => 'Manhattan Beach', 'long_name' => 'Manhattan Beach' },
                                                                                  { 'types' => ['postal_code'], 'short_name' => '12345', 'long_name' => '12345' },
                                                                                  { 'types' => ['street_number'], 'short_name' => '7', 'long_name' => '7' },
                                                                                  { 'types' => ['route'], 'short_name' => 'Calle Melancolia', 'long_name' => 'Calle Melancolia' }
                                                                                ]))
      expect(api_client).to receive(:spots).and_return([])
      place.save
      place.reload
      expect(place.name).to eq('Shark\'s Cove')
      expect(place.state).to eq('California')
      expect(place.administrative_level_1).to eq('CA')
      expect(place.administrative_level_2).to eq(nil)
    end
  end

  describe '#political_division' do
    it "should return the name in the locations if it's a sublocality" do
      sublocality = create(:place, name: 'Beverly Hills', types: ['sublocality'], route: nil, street_number: nil, city: 'Los Angeles', state: 'California', country: 'US')
      expect(Place.political_division(sublocality)).to eq(['North America', 'United States', 'California', 'Los Angeles', 'Beverly Hills'])
    end

    it 'should return the city in the locations' do
      bar = create(:place, types: ['establishment'], route: '1st st', street_number: '12 sdfsd', city: 'Los Angeles', state: 'California', country: 'US')
      expect(Place.political_division(bar)).to eq(['North America', 'United States', 'California', 'Los Angeles'])
    end

    it 'should return false if the place is a state and the are has cities of that state' do
      california = create(:place, types: ['locality'], route: nil, street_number: nil, city: nil, state: 'California', country: 'US')
      expect(Place.political_division(california)).to eq(['North America', 'United States', 'California'])
    end

    it 'returns nil if no place is given' do
      expect(Place.political_division(nil)).to be_nil
    end
  end

  describe '#locations' do
    it 'returns only the continent and country' do
      country = create(:place, name: 'United States', types: ['country'], route: nil, street_number: nil, city: nil, state: nil, country: 'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states'
      ])
    end

    it 'returns the state, continent and country' do
      country = create(:place, name: 'California', types: ['administrative_area_level_1'], route: nil, street_number: nil, city: nil, state: 'California', country: 'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states',
        'north america/united states/california'
      ])
    end

    it 'returns the citym state, continent and country' do
      country = create(:place, name: 'Los Angeles', types: ['locality'], route: nil, street_number: nil, city: 'Los Angeles', state: 'California', country: 'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states',
        'north america/united states/california',
        'north america/united states/california/los angeles'
      ])
    end

    it 'returns the citym state, continent and country' do
      country = create(:place, name: 'Beverly Hills', types: ['sublocality'], route: nil, street_number: nil, city: 'Los Angeles', state: 'California', country: 'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states',
        'north america/united states/california',
        'north america/united states/california/los angeles',
        'north america/united states/california/los angeles/beverly hills'
      ])
    end
  end

  describe '#combined_search', search: true do
    let(:google_results) { { results: [] } }
    let(:company_user) { create(:company_user, role: create(:non_admin_role)) }
    before { expect(Place).to receive(:open).and_return(double(read: JSON.generate(google_results))) }

    it 'should return empty if no results' do
      expect(Place.combined_search(q: 'aa')).to eql []
    end

    it 'should only places valid for the current user' do
      venue = create(:venue,
                                 place: create(:place, name: 'Qwerty', city: 'AB', state: 'California', country: 'CR'),
                                 company: company_user.company)
      create(:venue,
                         place: create(:place, name: 'Qwerty', city: 'XY', state: 'California', country: 'CR'),
                         company: company_user.company)

      Sunspot.commit

      company_user.places << create(:city, name: 'AB', state: 'California', country: 'CR')

      params = { q: 'qw', current_company_user: company_user }
      expect(Place.combined_search(params)).to eql [
        {
          value: 'Qwerty, 123 My Street',
          label: 'Qwerty, 123 My Street',
          id: venue.place_id,
          valid: true
        }
      ]
    end

    describe 'with results form Google API' do
      let(:google_results) do
        { results: [{
          'formatted_address' => 'Los Angeles, CA, USA',
          'id' => 'PLACEID1',
          'name' => 'Los Angeles',
          'reference' => 'REFERENCE1',
          'types' => %w(locality political)
        },
                    {
                      'formatted_address' => 'Los Angeles, ON, Canada',
                      'id' => 'PLACEID2',
                      'name' => 'Los Angeles',
                      'reference' => 'REFERENCE2',
                      'types' => %w(locality political)
                    }, {
                      'formatted_address' => 'Tower 42, Los Angeles, CA 23211, United States',
                      'id' => 'PLACEID3',
                      'name' => 'Vertigo 42',
                      'reference' => 'REFERENCE3',
                      'types' => %w(food bar establishment)
                    }] }
      end

      it "should include all the places returned by google with the 'valid' flag set to false" do
        params = { q: 'qw', current_company_user: company_user }
        expect(Place.combined_search(params)).to eql [
          {
            value: 'Los Angeles, CA, USA',
            label: 'Los Angeles, CA, USA',
            id: 'REFERENCE1||PLACEID1',
            valid: false
          },
          {
            value: 'Los Angeles, ON, Canada',
            label: 'Los Angeles, ON, Canada',
            id: 'REFERENCE2||PLACEID2',
            valid: false
          },
          {
            value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
            label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
            id: 'REFERENCE3||PLACEID3',
            valid: false
          }
        ]
      end

      it "should set the 'valid' flag to tru for places the user is allowed to access" do
        company_user.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
        params = { q: 'qw', current_company_user: company_user }
        expect(Place.combined_search(params)).to eql [
          {
            value: 'Los Angeles, CA, USA',
            label: 'Los Angeles, CA, USA',
            id: 'REFERENCE1||PLACEID1',
            valid: true
          },
          {
            value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
            label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
            id: 'REFERENCE3||PLACEID3',
            valid: true
          },
          {
            value: 'Los Angeles, ON, Canada',
            label: 'Los Angeles, ON, Canada',
            id: 'REFERENCE2||PLACEID2',
            valid: false
          }
        ]
      end

      it "returns mixed places from google and the app listing app's places first " do
        venue = create(:venue,
                                   place: create(:place, name: 'Qwerty', city: 'Los Angeles', state: 'California', country: 'US'),
                                   company: company_user.company)
        create(:venue,
                           place: create(:place, name: 'Qwerty', city: 'XY', state: 'California', country: 'CR'),
                           company: company_user.company)

        Sunspot.commit

        company_user.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')

        params = { q: 'Angeles', current_company_user: company_user }
        expect(Place.combined_search(params)).to eql [
          {
            value: 'Qwerty, 123 My Street',
            label: 'Qwerty, 123 My Street',
            id: venue.place_id,
            valid: true
          },
          {
            value: 'Los Angeles, CA, USA',
            label: 'Los Angeles, CA, USA',
            id: 'REFERENCE1||PLACEID1',
            valid: true
          },
          {
            value: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
            label: 'Vertigo 42, Tower 42, Los Angeles, CA 23211, United States',
            id: 'REFERENCE3||PLACEID3',
            valid: true
          },
          {
            value: 'Los Angeles, ON, Canada',
            label: 'Los Angeles, ON, Canada',
            id: 'REFERENCE2||PLACEID2',
            valid: false
          }
        ]
      end
    end
  end
end
