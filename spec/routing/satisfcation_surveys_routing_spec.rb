require "spec_helper"

describe SatisfactionSurveysController do
  describe "routing" do

    it "routes to #create" do
      post("/satisfaction").should route_to("satisfaction_surveys#create")
    end

  end
end