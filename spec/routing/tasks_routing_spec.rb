require "spec_helper"

describe TasksController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get("/tasks/mine")).to route_to("tasks#index", :scope => 'user')
      expect(get("/tasks/my_teams")).to route_to("tasks#index", :scope => 'teams')
    end

    it "routes to #new" do
      expect(get("/tasks/new")).to route_to("tasks#new")
    end

    it "routes to #edit" do
      expect(get("/tasks/1/edit")).to route_to("tasks#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/tasks")).to route_to("tasks#create")
    end

    it "routes to #update" do
      expect(put("/tasks/1")).to route_to("tasks#update", :id => "1")
    end

    describe "nested to events" do

      it "routes to #new" do
        expect(get("/events/1/tasks/new")).to route_to("tasks#new", :event_id => '1')
      end

      it "routes to #create" do
        expect(post("/events/1/tasks")).to route_to("tasks#create", :event_id => '1')
      end

    end

  end
end
