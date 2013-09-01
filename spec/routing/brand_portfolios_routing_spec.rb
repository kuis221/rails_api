require "spec_helper"

describe BrandPortfoliosController do
  describe "routing" do

    it "routes to #index" do
      get("/brand_portfolios").should route_to("brand_portfolios#index")
    end

    it "routes to #new" do
      get("/brand_portfolios/new").should route_to("brand_portfolios#new")
    end

    it "routes to #show" do
      get("/brand_portfolios/1").should route_to("brand_portfolios#show", :id => "1")
    end

    it "routes to #edit" do
      get("/brand_portfolios/1/edit").should route_to("brand_portfolios#edit", :id => "1")
    end

    it "routes to #create" do
      post("/brand_portfolios").should route_to("brand_portfolios#create")
    end

    it "routes to #update" do
      put("/brand_portfolios/1").should route_to("brand_portfolios#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/brand_portfolios/1").should route_to("brand_portfolios#destroy", :id => "1")
    end

    it "routes to #delete_brand" do
      delete("/brand_portfolios/1/brands/:brand_id").should route_to("brand_portfolios#delete_brand", :id => "1", :brand_id => ':brand_id')
    end

    it "routes to #select_brands" do
      get("/brand_portfolios/1/brands/select").should route_to("brand_portfolios#select_brands", :id => "1")
    end

    it "routes to #add_brands" do
      post("/brand_portfolios/1/brands/add").should route_to("brand_portfolios#add_brands", :id => "1")
    end

    it "routes to #brands" do
      get("/brand_portfolios/:brand_portfolio_id/brands").should route_to("brand_portfolios#brands", id: ':brand_portfolio_id', action: 'brands')
    end
  end
end
