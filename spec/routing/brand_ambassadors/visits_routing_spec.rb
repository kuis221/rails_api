require "rails_helper"

describe 'routes for brand ambassadors visits', :type => :routing do
  it "routes to #index" do
    expect(get: "/brand_ambassadors/visits").to route_to("brand_ambassadors/visits#index")
  end

  it "routes to #new" do
    expect(get: "/brand_ambassadors/visits/new").to route_to("brand_ambassadors/visits#new")
  end

  it "doesn't routes to #show" do
    expect(get: "/brand_ambassadors/visits/1").to route_to("brand_ambassadors/visits#show", id: '1')
  end

  it "doesn't routes to #edit" do
    expect(get: "/brand_ambassadors/visits/1/edit").to route_to("brand_ambassadors/visits#edit", id: '1')
  end

  it "routes to #create" do
    expect(post: "/brand_ambassadors/visits").to route_to("brand_ambassadors/visits#create")
  end

  it "routes to #update" do
    expect(put: "/brand_ambassadors/visits/1").to route_to("brand_ambassadors/visits#update", id: '1')
  end

  it "doesn't routes to #destroy" do
    expect(delete: "/brand_ambassadors/visits/1/folders/1").not_to be_routable
  end
end
