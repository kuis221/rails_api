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
#

require 'spec_helper'

describe Place do

  it { should validate_presence_of(:place_id) }
  it { should validate_presence_of(:reference) }

  describe "fetch_place_data" do
    it "should correctly assign the attributes returned by the api call" do
      place = Place.new(reference: 'YXZ', place_id: '123')
      api_client = double(:google_places_client)
      place.should_receive(:client).any_number_of_times.and_return(api_client)
      api_client.should_receive(:spot).with('YXZ').and_return(double(:spot, {
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
      api_client.should_receive(:spots).and_return([])

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
      place.should_receive(:client).any_number_of_times.and_return(api_client)
      api_client.should_receive(:spot).with('YXZ').and_return(double(:spot, {
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
      api_client.should_receive(:spots).and_return([])
      place.save
      place.reload
      place.name.should == 'Shark\'s Cove'
      place.state.should == 'California'
      place.administrative_level_1.should == 'CA'
      place.administrative_level_2.should == nil
    end
  end

  describe 'load_organized' do
    pending "should return the cities grouped by state and the states grouped by country" do
      Place.should_receive(:find).and_return([
        double(Place, id: 1, state_name: 'Ontario', city: 'Toronto', country_name: 'Canada', continent_name: 'North America'),
        double(Place, id: 2, state_name: 'Quebec', city: 'Montreal', country_name: 'Canada', continent_name: 'North America'),
        double(Place, id: 3, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 3, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 4, state_name: 'California', city: 'Los Angeles', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 5, state_name: 'Nevada', city: 'Las Vegas', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 6, state_name: 'Florida', city: 'Miami', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 7, state_name: 'Florida', city: 'Tampa', country_name: 'United States', continent_name: 'North America')
      ])
      structure = Place.load_organized(1, {})

      structure.map{|i| i[:label]}.should =~ ['United States', 'Canada']
      structure.map{|i| i[:items].map{|j| j[:label] }}.should =~ [['Ontario','Quebec'], ['California', 'Nevada', 'Florida']]
      structure.map{|i| i[:items].map{|j| j[:items].map{|k| k[:label] } }}.should =~ [[['Toronto'], ['Montreal']],[['San Francisco', 'Los Angeles'], ['Las Vegas'], ['Miami', 'Tampa']]]
    end

    pending "should return the cities grouped by state" do
      Place.should_receive(:find).and_return([
        double(Place, id: 1, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 2, state_name: 'California', city: 'Los Angeles', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 3, state_name: 'Nevada', city: 'Las Vegas', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 4, state_name: 'Florida', city: 'Miami', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 5, state_name: 'Florida', city: 'Tampa', country_name: 'United States', continent_name: 'North America')
      ])
      structure = Place.load_organized(1)
      structure.map{|i| i[:label]}.should =~ ['California', 'Nevada', 'Florida']
      structure.map{|i| i[:items].map{|j| j[:label] }}.should =~ [['San Francisco', 'Los Angeles'], ['Las Vegas'], ['Miami', 'Tampa']]
    end

    pending "should return only the cities if they are all within the same country and state" do
      Place.should_receive(:find).and_return([
        double(Place, id: 1, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 2, state_name: 'California', city: 'Los Angeles', country_name: 'United States', continent_name: 'North America')
      ])
      structure = Place.load_organized(1)
      structure.size.should == 2
      structure.map{|i| i[:label]}.should =~ ['San Francisco', 'Los Angeles']
      structure.map{|i| i[:items]}.should =~ [nil, nil]
    end

    pending "should not include the state if all the cities are inside the same state" do
      Place.should_receive(:find).and_return([
        double(Place, id: 1, state_name: 'Ontario', city: 'Toronto', country_name: 'Canada', continent_name: 'North America'),
        double(Place, id: 2, state_name: 'Ontario', city: 'Ottawa', country_name: 'Canada', continent_name: 'North America'),
        double(Place, id: 3, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 3, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 4, state_name: 'California', city: 'Los Angeles', country_name: 'United States', continent_name: 'North America'),
      ])
      structure = Place.load_organized(1)

      structure.map{|i| i[:label]}.should =~ ['United States', 'Canada']
      structure.map{|i| i[:items].map{|j| j[:label] }}.should =~ [['Toronto','Ottawa'], ['San Francisco', 'Los Angeles']]
      structure.map{|i| i[:items].map{|j| j[:items] }}.should =~ [[nil, nil],[nil, nil]]
    end


    pending "generate the correct ids for the cities/states/countries/continents" do
      Place.should_receive(:find).and_return([
        double(Place, id: 3, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 5, state_name: 'Nevada', city: 'Las Vegas', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 5, state_name: 'San Jose', city: 'Curridabat', country_name: 'Costa Rica', continent_name: 'South America')
      ])
      structure = Place.load_organized(1)

      structure.map{|i| i[:label]}.should =~ ['North America', 'South America']
      structure.map{|i| i[:id]}.should =~ ["NDYwNDkxZmM1MjBmNGRiZmNmZjIyZDFhNDVmNmIwNTZ8fE5vcnRoIEFtZXJpY2E=", "YjFmZjVmNTEyZjBmNWIxOTUyMDM5OGJmZmM3MzJhNmJ8fFNvdXRoIEFtZXJpY2E="]
      structure.map{|i| i[:items].map{|j| j[:label] }}.should =~ [["California", "Nevada"], ["Curridabat"]]
      structure.map{|i| i[:items].map{|j| j[:id] }}.should =~ [["OTI4MDU2MzcwYWRmZDAyNDMxYjJkNmVkODdhNTg5MGF8fEN1cnJpZGFiYXQ="], ["ZTY2OTRmNDViYTFiNWUzMGM5OWU2NGFlNjc2YzIyNDB8fENhbGlmb3JuaWE=", "M2JjNTIyMTQ4NTExOWIzYTFiMjI1ODE3N2I0NzUwZDJ8fE5ldmFkYQ=="]]
    end

    pending "should return only the area" do
      fake_collection  = double()
      Area.should_receive(:joins).and_return(fake_collection)
      fake_collection.stubs(:where).returns([
        double(Area, id: 1, name: 'Area of California', common_denominators: ['North America', 'United States', 'California']),
      ])
      structure = Place.load_organized(1)
      structure.map{|i| i[:label]}.should =~ ['Area of California']
    end

    pending "should place the area under the correct parent" do
      fake_collection  = double()
      Area.should_receive(:joins).and_return(fake_collection)
      fake_collection.stubs(:where).returns([
        double(Area, id: 1, name: 'Area of California', common_denominators: ['North America', 'United States', 'California']),
      ])
      Place.should_receive(:find).and_return([
        double(Place, id: 3, state_name: 'California', city: 'San Francisco', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 5, state_name: 'Nevada', city: 'Las Vegas', country_name: 'United States', continent_name: 'North America'),
        double(Place, id: 5, state_name: 'San Jose', city: 'Curridabat', country_name: 'Costa Rica', continent_name: 'South America')
      ])
      structure = Place.load_organized(1)
      structure.map{|i| i[:label]}.should =~ ['North America', 'South America']
      structure.map{|i| i[:items].map{|j| j[:label] }}.should =~ [["California", "Nevada"], ["Curridabat"]]
      structure.map{|i| i[:items].map{|j| j[:items].map{|k| k[:label]} if j[:items] }}.should =~ [[["Area of California", "San Francisco"], ["Las Vegas"]], [nil]]
    end
  end

  describe "#political_division" do
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
end
