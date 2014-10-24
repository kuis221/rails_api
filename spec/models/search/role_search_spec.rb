require 'rails_helper'

describe Role, type: :model, search: true do
  it 'should search for roles' do
    # First populate the Database with some data
    role = create(:role)
    role2 = create(:role)

    # Create a Role on company 2
    company2_role = create(:role, company_id: 2)

    # Search for all Roles on a given Company
    expect(search(company_id: 1))
      .to match_array([role, role2])
    expect(search(company_id: 2))
      .to match_array([company2_role])

    # Search for a given Role
    expect(search({ company_id: 1, q: "role,#{role.id}" }, true))
      .to match_array([role])

    # Search for Roles on a given status
    expect(search(company_id: 1, status: ['Active']))
      .to match_array([role, role2])
  end
end
