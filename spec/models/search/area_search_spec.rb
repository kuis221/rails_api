require 'rails_helper'

describe Area, type: :model, search: true do
  it "should search for areas" do
    # First populate the Database with some data
    area = FactoryGirl.create(:area)
    area2 = FactoryGirl.create(:area)

    # Create an Area on company 2
    company2_area = FactoryGirl.create(:area, company_id: 2)

    Sunspot.commit

    # Search for all Roles on a given Company
    expect(Area.do_search(company_id: 1).results).to match_array([area, area2])
    expect(Area.do_search(company_id: 2).results).to match_array([company2_area])

    # Search for a given Area
    expect(Area.do_search({company_id: 1, q: "area,#{area.id}"}, true).results).to match_array([area])

    # Search for Areas on a given status
    expect(Area.do_search(company_id: 1, status: ['Active']).results).to match_array([area, area2])
  end
end