require "spec_helper"

describe DateItemsController do
  describe "routing" do

    it "routes to #new" do
      get("/date_ranges/:range_id/dates/new").should route_to("date_items#new", :date_range_id => ':range_id')
    end

    it "routes to #create" do
      post("/date_ranges/:range_id/dates").should route_to("date_items#create", :date_range_id => ':range_id')
    end

    it "routes to #update" do
      put("/date_ranges/:range_id/dates/1").should route_to("date_items#update", :id => "1", :date_range_id => ':range_id')
    end

    it "routes to #destroy" do
      delete("/date_ranges/:range_id/dates/1").should route_to("date_items#destroy", :id => "1", :date_range_id => ':range_id')
    end

  end
end
