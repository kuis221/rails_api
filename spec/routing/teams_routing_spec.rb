require "spec_helper"

describe TeamsController do
  describe "routing" do

    it "routes to #index" do
      get("/admin/teams").should route_to("teams#index")
    end

    it "routes to #new" do
      get("/admin/teams/new").should route_to("teams#new")
    end

    it "routes to #show" do
      get("/admin/teams/1").should route_to("teams#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin/teams/1/edit").should route_to("teams#edit", :id => "1")
    end

    it "routes to #create" do
      post("/admin/teams").should route_to("teams#create")
    end

    it "routes to #update" do
      put("/admin/teams/1").should route_to("teams#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin/teams/1").should route_to("teams#destroy", :id => "1")
    end

    it "routes to #deactivate" do
      get("/admin/teams/1/deactivate").should route_to("teams#deactivate", :id => "1")
    end

    it "routes to #users" do
      get("/admin/teams/1/users").should route_to("teams#users", :id => "1")
    end

  end
end
