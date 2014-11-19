require 'rails_helper'

describe DayPart, type: :model, search: true do
  it 'should search for day parts' do
    # First populate the Database with some data
    day_part = create(:day_part)
    day_part2 = create(:day_part)

    # Create a Day Part on company 2
    company2_day_part = create(:day_part, company_id: 2)

    # Search for all Day Parts on a given Company
    expect(search(company_id: 1))
      .to match_array([day_part, day_part2])
    expect(search(company_id: 2))
      .to match_array([company2_day_part])

    # Search for a given Day Part
    expect(search({ company_id: 1, day_part: [day_part.id] }, true))
      .to match_array([day_part])

    # Search for Day Parts on a given status
    expect(search(company_id: 1, status: ['Active']))
      .to match_array([day_part, day_part2])
  end
end
