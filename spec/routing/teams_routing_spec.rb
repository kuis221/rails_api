require "rails_helper"

describe 'routes for teams', :type => :routing do
  it "routes to #index" do
    expect(get: "/teams").to route_to("teams#index")
  end

  it "routes to #new" do
    expect(get: "/teams/new").to route_to("teams#new")
  end

  it "routes to #show" do
    expect(get: "/teams/1").to route_to("teams#show", :id => "1")
  end

  it "routes to #edit" do
    expect(get: "/teams/1/edit").to route_to("teams#edit", :id => "1")
  end

  it "routes to #create" do
    expect(post: "/teams").to route_to("teams#create")
  end

  it "routes to #update" do
    expect(put: "/teams/1").to route_to("teams#update", :id => "1")
  end

  it "routes to #autocomplete" do
    expect(get: "/events/autocomplete").to route_to("events#autocomplete")
  end

  it "routes to #filters" do
    expect(get: "/events/filters").to route_to("events#filters")
  end

  it "routes to #items" do
    expect(get: "/events/items").to route_to("events#items")
  end

  it "doesn't routes to #destroy" do
    expect(delete: "/teams/1").not_to be_routable
  end

  it "routes to #deactivate" do
    expect(get: "/teams/1/deactivate").to route_to("teams#deactivate", :id => "1")
  end

  it "routes to #new_member" do
    expect(get: "/teams/1/members/new").to route_to("teams#new_member", :id => "1")
  end

  it "routes to #add_member" do
    expect(post: "/teams/1/members").to route_to("teams#add_members", :id => "1")
  end

  it "routes to #delete_member" do
    expect(delete: "/teams/1/members/2").to route_to("teams#delete_member", :id => "1", :member_id => "2")
  end
end
