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

require 'spec_helper'

describe Place do

  it { should validate_presence_of(:place_id) }
  it { should validate_presence_of(:reference) }

  it {should allow_value(nil).for(:country) }
  it {should allow_value('').for(:country) }
  it {should allow_value('US').for(:country) }
  it {should allow_value('CR').for(:country) }
  it {should allow_value('CA').for(:country) }
  it {should_not allow_value('ZZY').for(:country).with_message('is not valid') }
  it {should_not allow_value('Costa Rica').for(:country).with_message('is not valid') }
  it {should_not allow_value('United States').for(:country).with_message('is not valid') }

  describe "fetch_place_data" do
    it "should correctly assign the attributes returned by the api call" do
      place = Place.new(reference: 'YXZ', place_id: '123')
      api_client = double(:google_places_client)
      expect(place).to receive(:client).at_least(:once).and_return(api_client)
      expect(api_client).to receive(:spot).with('YXZ').and_return(double(:spot, {
          name: 'Rancho Grande',
          lat: '12.345678',
          lng: '-87.654321',
          formatted_address: '123 Mi Casa, Costa Rica',
          types: [1, 2, 3],
          address_components: [
            {'types' => ['country'],'short_name' => 'CR', 'long_name' => 'Costa Rica'},
            {'types' => ['administrative_area_level_1'],'short_name' => 'SJO', 'long_name' => 'San Jose'},
            {'types' => ['administrative_area_level_2'],'short_name' => 'SJ2', 'long_name' => 'Example'},
            {'types' => ['locality'],'short_name' => 'Curridabat', 'long_name' => 'Curridabat'},
            {'types' => ['postal_code'],'short_name' => '12345', 'long_name' => '12345'},
            {'types' => ['street_number'],'short_name' => '7', 'long_name' => '7'},
            {'types' => ['route'],'short_name' => 'Calle Melancolia', 'long_name' => 'Calle Melancolia'}
          ]
        }))
      expect(api_client).to receive(:spots).and_return([])

      place.save
      place.reload
      place.name.should == 'Rancho Grande'
      place.latitude.should == 12.345678
      place.longitude.should == -87.654321
      place.formatted_address.should == '123 Mi Casa, Costa Rica'
      place.types.should == [1, 2, 3]
      place.country.should == 'CR'
      place.city.should == 'Curridabat'
      place.state.should == 'San Jose'
      place.administrative_level_1.should == 'SJO'
      place.administrative_level_2.should == 'SJ2'
      place.zipcode.should == '12345'
      place.street_number.should == '7'
      place.route.should == 'Calle Melancolia'
    end

    it "should find out the correct state name if the API doesn't provide it" do
      place = Place.new(reference: 'YXZ', place_id: '123')
      api_client = double(:google_places_client)
      expect(place).to receive(:client).at_least(:once).and_return(api_client)
      expect(api_client).to receive(:spot).with('YXZ').and_return(double(:spot, {
          name: 'Shark\'s Cove',
          lat: '12.345678',
          lng: '-87.654321',
          formatted_address: '123 Mi Casa, Costa Rica',
          types: [1, 2, 3],
          address_components: [
            {'types' => ['country'],'short_name' => 'US', 'long_name' => 'United States'},
            {'types' => ['administrative_area_level_1'],'short_name' => 'CA', 'long_name' => 'CA'},
            {'types' => ['locality'],'short_name' => 'Manhattan Beach', 'long_name' => 'Manhattan Beach'},
            {'types' => ['postal_code'],'short_name' => '12345', 'long_name' => '12345'},
            {'types' => ['street_number'],'short_name' => '7', 'long_name' => '7'},
            {'types' => ['route'],'short_name' => 'Calle Melancolia', 'long_name' => 'Calle Melancolia'}
          ]
        }))
      expect(api_client).to receive(:spots).and_return([])
      place.save
      place.reload
      place.name.should == 'Shark\'s Cove'
      place.state.should == 'California'
      place.administrative_level_1.should == 'CA'
      place.administrative_level_2.should == nil
    end
  end

  describe "#political_division" do
    it "should return the name in the locations if it's a sublocality" do
      sublocality = FactoryGirl.create(:place, name: 'Beverly Hills', types: ['sublocality'], route: nil, street_number: nil, city: 'Los Angeles', state:'California', country:'US')
      Place.political_division(sublocality).should == ['North America', 'United States', 'California', 'Los Angeles', 'Beverly Hills']
    end

    it "should return the city in the locations" do
      bar = FactoryGirl.create(:place, types: ['establishment'], route:'1st st', street_number: '12 sdfsd', city: 'Los Angeles', state:'California', country:'US')
      Place.political_division(bar).should == ['North America', 'United States', 'California', 'Los Angeles']
    end

    it "should return false if the place is a state and the are has cities of that state" do
      california = FactoryGirl.create(:place, types: ['locality'], route:nil, street_number: nil, city: nil, state:'California', country:'US')
      Place.political_division(california).should == ['North America', 'United States', 'California']
    end

    it "returns nil if no place is given" do
      Place.political_division(nil).should be_nil
    end
  end

  describe "#locations" do
    it "returns only the continent and country" do
      country = FactoryGirl.create(:place, name: 'United States', types: ['country'], route: nil, street_number: nil, city: nil, state:nil, country:'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states'
      ])
    end

    it "returns the state, continent and country" do
      country = FactoryGirl.create(:place, name: 'California', types: ['administrative_area_level_1'], route: nil, street_number: nil, city: nil, state:'California', country:'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states',
        'north america/united states/california'
      ])
    end

    it "returns the citym state, continent and country" do
      country = FactoryGirl.create(:place, name: 'Los Angeles', types: ['locality'], route: nil, street_number: nil, city: 'Los Angeles', state:'California', country:'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states',
        'north america/united states/california',
        'north america/united states/california/los angeles'
      ])
    end


    it "returns the citym state, continent and country" do
      country = FactoryGirl.create(:place, name: 'Beverly Hills', types: ['sublocality'], route: nil, street_number: nil, city: 'Los Angeles', state:'California', country:'US')
      expect(country.locations.map(&:path)).to match_array([
        'north america',
        'north america/united states',
        'north america/united states/california',
        'north america/united states/california/los angeles',
        'north america/united states/california/los angeles/beverly hills'
      ])
    end
  end
end
