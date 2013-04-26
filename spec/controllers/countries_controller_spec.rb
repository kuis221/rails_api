require 'spec_helper'

describe CountriesController do

  describe "GET 'states'" do
    it "returns http success" do
      get 'states', country: 'US', format: :json
      response.should be_success
    end
  end

end
