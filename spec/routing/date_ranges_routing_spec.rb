require "spec_helper"

describe DateRangesController do
  describe "routing" do

    it "routes to #index" do
      get("/date_ranges").should route_to("date_ranges#index")
    end

    it "routes to #new" do
      get("/date_ranges/new").should route_to("date_ranges#new")
    end

    it "routes to #show" do
      get("/date_ranges/1").should route_to("date_ranges#show", :id => "1")
    end

    it "routes to #edit" do
      get("/date_ranges/1/edit").should route_to("date_ranges#edit", :id => "1")
    end

    it "routes to #create" do
      post("/date_ranges").should route_to("date_ranges#create")
    end

    it "routes to #update" do
      put("/date_ranges/1").should route_to("date_ranges#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/date_ranges/1").should route_to("date_ranges#destroy", :id => "1")
    end

  end
end
