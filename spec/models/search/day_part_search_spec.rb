require 'spec_helper'

describe DayPart, type: :model, search: true do
  it "should search for day parts" do
    # First populate the Database with some data
    day_part = FactoryGirl.create(:day_part)
    day_part2 = FactoryGirl.create(:day_part)

    # Create a Day Part on company 2
    company2_day_part = FactoryGirl.create(:day_part, company_id: 2)

    Sunspot.commit

    # Search for all Day Parts on a given Company
    expect(DayPart.do_search(company_id: 1).results).to match_array([day_part, day_part2])
    expect(DayPart.do_search(company_id: 2).results).to match_array([company2_day_part])

    # Search for a given Day Part
    expect(DayPart.do_search({company_id: 1, q: "day_part,#{day_part.id}"}, true).results).to match_array([day_part])

    # Search for Day Parts on a given status
    expect(DayPart.do_search(company_id: 1, status: ['Active']).results).to match_array([day_part, day_part2])
  end
end