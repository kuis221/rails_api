require 'spec_helper'

describe Area, search: true do
  it "should search for areas" do
    # First populate the Database with some data
    area = FactoryGirl.create(:area)
    area2 = FactoryGirl.create(:area)

    # Create an Area on company 2
    company2_area = FactoryGirl.create(:area, company_id: 2)

    Sunspot.commit

    # Search for all Events on a given Company
    Area.do_search(company_id: 1).results.should =~ [area, area2]
    Area.do_search(company_id: 2).results.should =~ [company2_area]

    # Search for a given Area
    Area.do_search({company_id: 1, q: "area,#{area.id}"}, true).results.should =~ [area]
  end
end