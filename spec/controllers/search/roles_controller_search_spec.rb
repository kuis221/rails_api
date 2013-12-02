require 'spec_helper'

describe RolesController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Roles']
    end

    it "should return the roles in the Roles Bucket" do
      role = FactoryGirl.create(:role, name: 'Role 1', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'rol'
      response.should be_success

      buckets = JSON.parse(response.body)
      roles_bucket = buckets.select{|b| b['label'] == 'Roles'}.first
      roles_bucket['value'].should == [{"label"=>"<i>Rol</i>e 1", "value"=>role.id.to_s, "type"=>"role"}]
    end
  end

  describe "GET 'filters'" do
    it "should return the correct filters in the right order" do
      Sunspot.commit
      get 'filters', format: :json
      response.should be_success

      filters = JSON.parse(response.body)
      filters['filters'].map{|b| b['label']}.should == ["Active State"]
    end
  end
end