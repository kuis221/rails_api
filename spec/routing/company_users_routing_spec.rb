require "spec_helper"

describe CompanyUsersController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get("/users")).to route_to("company_users#index")
    end

    it "routes to #index.table" do
      expect(get("/users.json")).to route_to("company_users#index", format: 'json')
    end

    it "routes to #show" do
      expect(get("/users/1")).to route_to("company_users#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/users/1/edit")).to route_to("company_users#edit", :id => "1")
    end

    it "routes to #update" do
      expect(put("/users/1")).to route_to("company_users#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/users/1")).not_to route_to("company_users#destroy", :id => "1")
    end

    it "routes to #deactivate" do
      expect(get("/users/1/deactivate")).to route_to("company_users#deactivate", :id => "1")
    end

  end
end
