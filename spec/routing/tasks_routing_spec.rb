require "spec_helper"

describe TasksController do
  describe "routing" do

    it "routes to #index" do
      get("/tasks/mine").should route_to("tasks#index", :scope => 'user')
      get("/tasks/my_teams").should route_to("tasks#index", :scope => 'teams')
    end

    it "routes to #new" do
      get("/tasks/new").should route_to("tasks#new")
    end

    it "routes to #edit" do
      get("/tasks/1/edit").should route_to("tasks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/tasks").should route_to("tasks#create")
    end

    it "routes to #update" do
      put("/tasks/1").should route_to("tasks#update", :id => "1")
    end

    describe "nested to events" do

      it "routes to #new" do
        get("/events/1/tasks/new").should route_to("tasks#new", :event_id => '1')
      end

      it "routes to #create" do
        post("/events/1/tasks").should route_to("tasks#create", :event_id => '1')
      end

    end

  end
end
