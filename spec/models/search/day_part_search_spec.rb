require 'spec_helper'

describe DayPart, search: true do
  it "should search for day parts" do
    # First populate the Database with some data
    day_part = FactoryGirl.create(:day_part)
    day_part2 = FactoryGirl.create(:day_part)

    # Create a Day Part on company 2
    company2_day_part = FactoryGirl.create(:day_part, company_id: 2)

    Sunspot.commit

    # Search for all Day Parts on a given Company
    DayPart.do_search(company_id: 1).results.should =~ [day_part, day_part2]
    DayPart.do_search(company_id: 2).results.should =~ [company2_day_part]

    # Search for a given Day Part
    DayPart.do_search({company_id: 1, q: "day_part,#{day_part.id}"}, true).results.should =~ [day_part]

    # Search for Day Parts on a given status
    DayPart.do_search(company_id: 1, status: ['Active']).results.should =~ [day_part, day_part2]
  end
end