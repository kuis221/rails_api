require 'spec_helper'

describe Place, search: true do
  it "should search for places" do
    # First populate the Database with some data
    place = FactoryGirl.create(:place, name: 'Island Creek Oyster Bar', city: "Boston", latitude: '42.348774', longitude: '-71.094994')
    place2 = FactoryGirl.create(:place, name: 'Bar None', city: "San Francisco", latitude: '37.79764', longitude: '-122.431913')

    Sunspot.commit

    # Search for all Places
    Place.do_search({}).results.should =~ [place, place2]
  end
end