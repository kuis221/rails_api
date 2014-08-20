require "rails_helper"

describe "routes for satisfaction surveys", :type => :routing do
  it "routes to #create" do
    expect(post: "/satisfaction").to route_to("satisfaction_surveys#create")
  end

  it "does't routes to #destroy" do
    expect(delete: "/satisfaction/1").not_to be_routable
  end
end