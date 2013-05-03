require "spec_helper"

describe TasksController do
  describe "routing" do

    it "routes to #index" do
      get("/events/1/tasks").should route_to("tasks#index", :event_id => '1')
    end

    it "routes to #new" do
      get("/events/1/tasks/new").should route_to("tasks#new", :event_id => '1')
    end

    it "routes to #show" do
      get("/events/1/tasks/1").should route_to("tasks#show", :event_id => '1', :id => "1")
    end

    it "routes to #edit" do
      get("/events/1/tasks/1/edit").should route_to("tasks#edit", :event_id => '1', :id => "1")
    end

    it "routes to #create" do
      post("/events/1/tasks").should route_to("tasks#create", :event_id => '1')
    end

    it "routes to #update" do
      put("/events/1/tasks/1").should route_to("tasks#update", :event_id => '1', :id => "1")
    end

    it "routes to #destroy" do
      delete("/events/1/tasks/1").should route_to("tasks#destroy", :event_id => '1', :id => "1")
    end

  end
end
