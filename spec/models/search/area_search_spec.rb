require 'rails_helper'

describe Area, type: :model, search: true do
  it 'should search for areas' do
    # First populate the Database with some data
    area = create(:area, company_id: 1)
    area2 = create(:area, company_id: 1)

    # Create an Area on company 2
    company2_area = create(:area, company_id: 2)

    # Search for all Roles on a given Company
    expect(search(company_id: 1)).to match_array([area, area2])
    expect(search(company_id: 2)).to match_array([company2_area])

    # Search for a given Area
    expect(search(company_id: 1, area: [area.id])).to match_array([area])

    # Search for Areas on a given status
    expect(search(company_id: 1, status: ['Active'])).to match_array([area, area2])
  end
end
