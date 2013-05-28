require "spec_helper"

describe BrandsController do
  describe "routing" do

    it "routes to #index" do
      get("/campaigns/:campaign_id/brands").should route_to("brands#index", campaign_id: ':campaign_id')
    end

  end
end
