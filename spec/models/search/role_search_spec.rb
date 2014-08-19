require 'rails_helper'

describe Role, type: :model, search: true do
  it "should search for roles" do
    # First populate the Database with some data
    role = FactoryGirl.create(:role)
    role2 = FactoryGirl.create(:role)

    # Create a Role on company 2
    company2_role = FactoryGirl.create(:role, company_id: 2)

    Sunspot.commit

    # Search for all Roles on a given Company
    expect(Role.do_search(company_id: 1).results).to match_array([role, role2])
    expect(Role.do_search(company_id: 2).results).to match_array([company2_role])

    # Search for a given Role
    expect(Role.do_search({company_id: 1, q: "role,#{role.id}"}, true).results).to match_array([role])

    # Search for Roles on a given status
    expect(Role.do_search(company_id: 1, status: ['Active']).results).to match_array([role, role2])
  end
end