require 'spec_helper'

describe CountriesController, :type => :controller do

  describe "GET 'states'" do
    it "returns http success" do
      get 'states', country: 'US', format: :json
      expect(response).to be_success
    end
  end
end
