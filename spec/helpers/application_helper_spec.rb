require 'spec_helper'

describe ApplicationHelper do
  describe "#place_address" do
    it "should add the name to the address" do
      place= double(Place, {name: 'Some Place Name', street: nil, state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name</address>", helper.place_address(place)
    end

    it "should add the street to the address" do
      place= double(Place, {name: 'Some Place Name', street: 'Street Name', state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name<br/>Street Name</address>", helper.place_address(place)
    end

    it "should not add the street to the address if it's the same as the place name" do
      place= double(Place, {name: 'Some Place Name', street: 'Some Place Name', state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name</address>", helper.place_address(place)
    end

    it "should not add the street if it has an empty string or with spaces" do
      place= double(Place, {name: 'Some Place Name', street: ' ', state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name</address>", helper.place_address(place)
    end

    it "should add the city to the address" do
      place= double(Place, {name: nil, street: nil, state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil})
      assert_dom_equal "<address>Curridabat</address>", helper.place_address(place)
    end

    it "should add the name and city to the address is separated lines" do
      place= double(Place, {name: 'Place name', street: nil, state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil})
      assert_dom_equal "<address>Place name<br />Curridabat</address>", helper.place_address(place)
    end

    it "should add the name, street and city to the address is separated lines" do
      place= double(Place, {name: 'Place name', street: '123 uno dos tres', state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil})
      assert_dom_equal "<address>Place name<br />123 uno dos tres<br />Curridabat</address>", helper.place_address(place)
    end

    pending "should add the state to the address" do
      place= double(Place, {name: nil, street: nil, state: 'California', zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>California</address>", helper.place_address(place)
    end

    pending "should add the state and the zipcode to the address separated by a commma" do
      place= double(Place, {name: nil, street: nil, state: 'California', zipcode: '90210', city: nil, formatted_address: nil})
      assert_dom_equal "<address>California, 90210</address>", helper.place_address(place)
    end

    it "should add the city, state and the zipcode to the address separated by a commma" do
      place= double(Place, {name: nil, street: nil, state: 'California', zipcode: '90210', city: 'Beverly Hills', formatted_address: nil})
      assert_dom_equal "<address>Beverly Hills, California, 90210</address>", helper.place_address(place)
    end
  end
end