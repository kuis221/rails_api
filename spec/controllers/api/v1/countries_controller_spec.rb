require 'spec_helper'

describe Api::V1::CountriesController, :type => :controller do
  let(:user) { sign_in_as_user }

  describe "#index" do
    it "returns a list of countries" do
      get 'index', auth_token: user.authentication_token, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include({'id' => 'US', 'name' => 'United States'})
    end
  end

  describe "#states" do
    it "returns a list of countries" do
      get 'states', auth_token: user.authentication_token, id: 'US', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include({'id' => 'CA', 'name' => 'California'})
    end
  end
end