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
#

require 'spec_helper'

describe Place do

  it { should validate_presence_of(:place_id) }
  it { should validate_presence_of(:reference) }

  describe "fetch_place_data" do
    it "should correctly assign the attributes returned by the api call" do
      place = Place.new(reference: 'YXZ', place_id: '123')
      api_client = double(:google_places_client)
      place.should_receive(:client).and_return(api_client)
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
  end
end
