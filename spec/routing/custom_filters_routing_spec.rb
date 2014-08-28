require "rails_helper"

describe 'routes for custom filters', :type => :routing do
  it "routes to #index" do
    expect(get: "/custom_filters").to route_to("custom_filters#index")
  end

  it "routes to #new" do
    expect(get: "/custom_filters/new").to route_to("custom_filters#new")
  end

  it "routes to #create" do
    expect(post: "/custom_filters").to route_to("custom_filters#create")
  end

  it "routes to #destroy" do
    expect(delete: "/custom_filters/1").to route_to("custom_filters#destroy", :id => "1")
  end
end
