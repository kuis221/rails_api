require "spec_helper"

describe InvitationsController, :type => :routing do
  describe "routing" do

    it "routes to #edit" do
      expect(get("/users/invitation/accept")).to route_to("invitations#edit")
    end

    it "routes to #destroy" do
      expect(get("/users/invitation/remove")).to route_to("invitations#destroy")
    end

    it "routes to #new" do
      expect(get("/users/invitation/new")).to route_to("invitations#new")
    end

    it "routes to #show" do
      expect(put("/users/invitation")).to route_to("invitations#update")
    end

    it "routes to #create" do
      expect(post("/users/invitation")).to route_to("invitations#create")
    end
  end
end
