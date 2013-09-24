require 'spec_helper'

describe DateRange, search: true do
  it "should search for date ranges" do
    # First populate the Database with some data
    date_range = FactoryGirl.create(:date_range)
    date_range2 = FactoryGirl.create(:date_range)

    # Create a Date Range on company 2
    company2_date_range = FactoryGirl.create(:date_range, company_id: 2)

    Sunspot.commit

    # Search for all Date Ranges on a given Company
    DateRange.do_search(company_id: 1).results.should =~ [date_range, date_range2]
    DateRange.do_search(company_id: 2).results.should =~ [company2_date_range]

    # Search for a given Date Range
    DateRange.do_search({company_id: 1, q: "date_range,#{date_range.id}"}, true).results.should =~ [date_range]

    # Search for Date Ranges on a given status
    DateRange.do_search(company_id: 1, status: ['Active']).results.should =~ [date_range, date_range2]
  end
end