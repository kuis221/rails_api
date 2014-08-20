require 'rails_helper'

describe RolesController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map{|b| b['label']}).to eq(['Roles'])
    end

    it "should return the roles in the Roles Bucket" do
      role = FactoryGirl.create(:role, name: 'Role 1', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'rol'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      roles_bucket = buckets.select{|b| b['label'] == 'Roles'}.first
      expect(roles_bucket['value']).to eq([{"label"=>"<i>Rol</i>e 1", "value"=>role.id.to_s, "type"=>"role"}])
    end
  end

  describe "GET 'filters'" do
    it "should return the correct filters in the right order" do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map{|b| b['label']}).to eq(["Active State"])
    end
  end
end