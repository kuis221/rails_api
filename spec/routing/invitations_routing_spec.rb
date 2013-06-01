require "spec_helper"

describe InvitationsController do
  describe "routing" do

    it "routes to #edit" do
      get("/users/invitation/accept").should route_to("invitations#edit")
    end

    it "routes to #destroy" do
      get("/users/invitation/remove").should route_to("invitations#destroy")
    end

    it "routes to #new" do
      get("/users/invitation/new").should route_to("invitations#new")
    end

    it "routes to #show" do
      put("/users/invitation").should route_to("invitations#update")
    end

    it "routes to #create" do
      post("/users/invitation").should route_to("invitations#create")
    end
  end
end
