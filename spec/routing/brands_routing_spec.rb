require "spec_helper"

describe BrandsController, :type => :routing do
  describe "routing" do

    describe "nested to campaigns" do
      it "routes to #index" do
        #get("/campaigns/:campaign_id/brands").should route_to("brands#index", campaign_id: ':campaign_id')
      end
    end

    describe "nested to brand portfolios" do
      it "routes to #new" do
        expect(get("/brand_portfolios/:brand_portfolio_id/brands/new")).to route_to("brands#new", brand_portfolio_id: ':brand_portfolio_id')
      end
      it "routes to #create" do
        expect(post("/brand_portfolios/:brand_portfolio_id/brands")).to route_to("brands#create", brand_portfolio_id: ':brand_portfolio_id')
      end
    end
  end
end
