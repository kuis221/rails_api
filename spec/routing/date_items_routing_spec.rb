require "spec_helper"

describe DateItemsController, :type => :routing do
  describe "routing" do

    it "routes to #new" do
      expect(get("/date_ranges/:range_id/dates/new")).to route_to("date_items#new", :date_range_id => ':range_id')
    end

    it "routes to #create" do
      expect(post("/date_ranges/:range_id/dates")).to route_to("date_items#create", :date_range_id => ':range_id')
    end

    it "routes to #destroy" do
      expect(delete("/date_ranges/:range_id/dates/1")).to route_to("date_items#destroy", :id => "1", :date_range_id => ':range_id')
    end

  end
end
