require "spec_helper"

describe CampaignsController do
  describe "routing" do

    it "routes to #index" do
      get("/campaigns").should route_to("campaigns#index")
    end

    it "routes to #new" do
      get("/campaigns/new").should route_to("campaigns#new")
    end

    it "routes to #show" do
      get("/campaigns/1").should route_to("campaigns#show", :id => "1")
    end

    it "routes to #edit" do
      get("/campaigns/1/edit").should route_to("campaigns#edit", :id => "1")
    end

    it "routes to #create" do
      post("/campaigns").should route_to("campaigns#create")
    end

    it "routes to #update" do
      put("/campaigns/1").should route_to("campaigns#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/campaigns/1").should route_to("campaigns#destroy", :id => "1")
    end

    it "routes to #deactivate" do
      get("/campaigns/1/deactivate").should route_to("campaigns#deactivate", :id => "1")
    end

    it "routes to #delete_member" do
      delete("/campaigns/1/members/2").should route_to("campaigns#delete_member", :id => "1", :member_id => "2")
      delete("/campaigns/1/teams/2").should route_to("campaigns#delete_member", :id => "1", :team_id => "2")
    end

    it "routes to #new_member" do
      get("/campaigns/1/members/new").should route_to("campaigns#new_member", :id => "1")
    end

    it "routes to #add_members" do
      post("/campaigns/1/members").should route_to("campaigns#add_members", :id => "1")
    end

    it "routes to #members" do
      get("/campaigns/1/members").should route_to("campaigns#members", :id => "1")
    end

    it "routes to #teams" do
      get("/campaigns/1/teams").should route_to("campaigns#teams", :id => "1")
    end

    it "routes to #tab" do
      get("/campaigns/1/tab/staff").should route_to("campaigns#tab", :id => "1", tab: 'staff')
      get("/campaigns/1/tab/places").should route_to("campaigns#tab", :id => "1", tab: 'places')
      get("/campaigns/1/tab/date_ranges").should route_to("campaigns#tab", :id => "1", tab: 'date_ranges')
      get("/campaigns/1/tab/day_parts").should route_to("campaigns#tab", :id => "1", tab: 'day_parts')
    end

    it "routes to #find_similar_kpi" do
      get("/campaigns/find_similar_kpi").should route_to("campaigns#find_similar_kpi")
    end

    it "routes to #post_event_form" do
      get("/campaigns/1/post_event_form").should route_to("campaigns#post_event_form", :id => "1")
    end

    it "routes to #update_post_event_form" do
      post("/campaigns/1/update_post_event_form").should route_to("campaigns#update_post_event_form", :id => "1")
    end

    it "routes to #select_kpis" do
      get("/campaigns/1/kpis/select").should route_to("campaigns#select_kpis", :id => "1")
    end

    it "routes to #add_kpi" do
      post("/campaigns/1/kpis/add").should route_to("campaigns#add_kpi", :id => "1")
    end

    it "routes to #remove_kpi" do
      delete("/campaigns/1/kpis/1").should route_to("campaigns#remove_kpi", :id => "1", :kpi_id => "1")
    end

    it "routes to #add_activity_type" do
      post("/campaigns/1/activity_types/add").should route_to("campaigns#add_activity_type", :id => "1")
    end

    it "routes to #remove_activity_type" do
      delete("/campaigns/1/activity_types/1").should route_to("campaigns#remove_activity_type", :id => "1", :activity_type_id => "1")
    end
  end
end
