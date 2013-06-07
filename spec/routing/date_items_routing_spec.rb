require "spec_helper"

describe DateItemsController do
  describe "routing" do

    it "routes to #index" do
      get("/date_items").should route_to("date_items#index")
    end

    it "routes to #new" do
      get("/date_items/new").should route_to("date_items#new")
    end

    it "routes to #show" do
      get("/date_items/1").should route_to("date_items#show", :id => "1")
    end

    it "routes to #edit" do
      get("/date_items/1/edit").should route_to("date_items#edit", :id => "1")
    end

    it "routes to #create" do
      post("/date_items").should route_to("date_items#create")
    end

    it "routes to #update" do
      put("/date_items/1").should route_to("date_items#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/date_items/1").should route_to("date_items#destroy", :id => "1")
    end

  end
end
