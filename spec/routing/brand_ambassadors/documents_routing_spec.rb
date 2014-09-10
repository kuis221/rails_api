require "rails_helper"

describe 'routes for brand ambassadors documents', :type => :routing do
  it "doesn't routes to #index" do
    expect(get: "/brand_ambassadors/documents").not_to be_routable
  end

  it "routes to #new" do
    expect(get: "/brand_ambassadors/documents/new").to route_to("brand_ambassadors/documents#new")
  end

  it "doesn't routes to #show" do
    expect(get: "/brand_ambassadors/documents/1").not_to be_routable
  end

  it "routes to #edit" do
    expect(get: "/brand_ambassadors/documents/1/edit").to route_to("brand_ambassadors/documents#edit", id: '1')
  end

  it "routes to #create" do
    expect(post: "/brand_ambassadors/documents").to route_to("brand_ambassadors/documents#create")
  end

  it "routes to #update" do
    expect(put: "/brand_ambassadors/documents/1").to route_to("brand_ambassadors/documents#update", id: '1')
  end

  it "routes to #destroy" do
    expect(delete: "/brand_ambassadors/documents/1").to route_to("brand_ambassadors/documents#destroy", id: '1')
  end
end


describe 'routes for brand ambassadors documents nested inside a visit', :type => :routing do
  it "doesn't routes to #index" do
    expect(get: "/brand_ambassadors/visits/1/documents").not_to be_routable
  end

  it "routes to #new" do
    expect(get: "/brand_ambassadors/visits/1/documents/new").to route_to("brand_ambassadors/documents#new", visit_id: '1')
  end

  it "doesn't routes to #show" do
    expect(get: "/brand_ambassadors/visits/1/documents/1").not_to be_routable
  end

  it "doesn't routes to #edit" do
    expect(get: "/brand_ambassadors/visits/1/documents/1/edit").not_to be_routable
  end

  it "routes to #create" do
    expect(post: "/brand_ambassadors/visits/1/documents").to route_to("brand_ambassadors/documents#create", visit_id: '1')
  end

  it "doesn't routes to #update" do
    expect(put: "/brand_ambassadors/visits/1/documents/1").not_to be_routable
  end

  it "doesn't routes to #destroy" do
    expect(delete: "/brand_ambassadors/visits/1/documents/1").not_to be_routable
  end
end
