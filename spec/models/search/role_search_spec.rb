require 'spec_helper'

describe Role, search: true do
  it "should search for roles" do
    # First populate the Database with some data
    role = FactoryGirl.create(:role)
    role2 = FactoryGirl.create(:role)

    # Create a Role on company 2
    company2_role = FactoryGirl.create(:role, company_id: 2)

    Sunspot.commit

    # Search for all Roles on a given Company
    Role.do_search(company_id: 1).results.should =~ [role, role2]
    Role.do_search(company_id: 2).results.should =~ [company2_role]

    # Search for a given Role
    Role.do_search({company_id: 1, q: "role,#{role.id}"}, true).results.should =~ [role]

    # Search for Roles on a given status
    Role.do_search(company_id: 1, status: ['Active']).results.should =~ [role, role2]
  end
end