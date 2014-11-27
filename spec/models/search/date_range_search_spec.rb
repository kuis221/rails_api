require 'rails_helper'

describe DateRange, type: :model, search: true do
  it 'should search for date ranges' do
    # First populate the Database with some data
    date_range = create(:date_range)
    date_range2 = create(:date_range)

    # Create a Date Range on company 2
    company2_date_range = create(:date_range, company_id: 2)

    # Search for all Date Ranges on a given Company
    expect(search(company_id: 1))
      .to match_array([date_range, date_range2])
    expect(search(company_id: 2))
      .to match_array([company2_date_range])

    # Search for a given Date Range
    expect(search({ company_id: 1, date_range: [date_range.id] }, true))
      .to match_array([date_range])

    # Search for Date Ranges on a given status
    expect(search(company_id: 1, status: ['Active']))
      .to match_array([date_range, date_range2])
  end
end
