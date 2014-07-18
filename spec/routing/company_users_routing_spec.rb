require "spec_helper"

describe CompanyUsersController do
  describe "routing" do

    it "routes to #index" do
      get("/users").should route_to("company_users#index")
    end

    it "routes to #index.table" do
      get("/users.json").should route_to("company_users#index", format: 'json')
    end

    it "routes to #show" do
      get("/users/1").should route_to("company_users#show", :id => "1")
    end

    it "routes to #edit" do
      get("/users/1/edit").should route_to("company_users#edit", :id => "1")
    end

    it "routes to #update" do
      put("/users/1").should route_to("company_users#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/users/1").should_not route_to("company_users#destroy", :id => "1")
    end

    it "routes to #deactivate" do
      get("/users/1/deactivate").should route_to("company_users#deactivate", :id => "1")
    end

    it "routes to #profile" do
      get("/users/profile").should route_to("company_users#profile")
    end

    it "routes to #verify_phone" do
      post("/users/1/verify_phone").should route_to("company_users#verify_phone", :id => "1")
    end

    it "routes to #verify_phone" do
      get("/users/1/send_code").should route_to("company_users#send_code", :id => "1")
    end

  end
end
