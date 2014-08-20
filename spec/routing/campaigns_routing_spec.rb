require "rails_helper"

describe 'routes for campaigns', :type => :routing do
  it "routes to #index" do
    expect(get: "/campaigns").to route_to("campaigns#index")
  end

  it "routes to #new" do
    expect(get: "/campaigns/new").to route_to("campaigns#new")
  end

  it "routes to #show" do
    expect(get: "/campaigns/1").to route_to("campaigns#show", :id => "1")
  end

  it "routes to #edit" do
    expect(get: "/campaigns/1/edit").to route_to("campaigns#edit", :id => "1")
  end

  it "routes to #create" do
    expect(post: "/campaigns").to route_to("campaigns#create")
  end

  it "routes to #update" do
    expect(put: "/campaigns/1").to route_to("campaigns#update", :id => "1")
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
    expect(delete: "/campaigns/1").not_to be_routable
  end

  it "routes to #deactivate" do
    expect(get: "/campaigns/1/deactivate").to route_to("campaigns#deactivate", :id => "1")
  end

  it "routes to #delete_member" do
    expect(delete: "/campaigns/1/members/2").to route_to("campaigns#delete_member", :id => "1", :member_id => "2")
    expect(delete: "/campaigns/1/teams/2").to route_to("campaigns#delete_member", :id => "1", :team_id => "2")
  end

  it "routes to #new_member" do
    expect(get: "/campaigns/1/members/new").to route_to("campaigns#new_member", :id => "1")
  end

  it "routes to #add_members" do
    expect(post: "/campaigns/1/members").to route_to("campaigns#add_members", :id => "1")
  end

  it "routes to #members" do
    expect(get: "/campaigns/1/members").to route_to("campaigns#members", :id => "1")
  end

  it "routes to #teams" do
    expect(get: "/campaigns/1/teams").to route_to("campaigns#teams", :id => "1")
  end

  it "routes to #tab" do
    expect(get: "/campaigns/1/tab/staff").to route_to("campaigns#tab", :id => "1", tab: 'staff')
    expect(get: "/campaigns/1/tab/places").to route_to("campaigns#tab", :id => "1", tab: 'places')
    expect(get: "/campaigns/1/tab/date_ranges").to route_to("campaigns#tab", :id => "1", tab: 'date_ranges')
    expect(get: "/campaigns/1/tab/day_parts").to route_to("campaigns#tab", :id => "1", tab: 'day_parts')
  end

  it "routes to #find_similar_kpi" do
    expect(get: "/campaigns/find_similar_kpi").to route_to("campaigns#find_similar_kpi")
  end

  it "routes to #post_event_form" do
    expect(get: "/campaigns/1/post_event_form").to route_to("campaigns#post_event_form", :id => "1")
  end

  it "routes to #update_post_event_form" do
    expect(post: "/campaigns/1/update_post_event_form").to route_to("campaigns#update_post_event_form", :id => "1")
  end

  it "routes to #select_kpis" do
    expect(get: "/campaigns/1/kpis/select").to route_to("campaigns#select_kpis", :id => "1")
  end

  it "routes to #add_kpi" do
    expect(post: "/campaigns/1/kpis/add").to route_to("campaigns#add_kpi", :id => "1")
  end

  it "routes to #remove_kpi" do
    expect(delete: "/campaigns/1/kpis/1").to route_to("campaigns#remove_kpi", :id => "1", :kpi_id => "1")
  end

  it "routes to #add_activity_type" do
    expect(post: "/campaigns/1/activity_types/add").to route_to("campaigns#add_activity_type", :id => "1")
  end

  it "routes to #remove_activity_type" do
    expect(delete: "/campaigns/1/activity_types/1").to route_to("campaigns#remove_activity_type", :id => "1", :activity_type_id => "1")
  end
end
