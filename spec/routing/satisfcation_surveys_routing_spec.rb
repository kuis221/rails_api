require "spec_helper"

describe SatisfactionSurveysController, :type => :routing do
  describe "routing" do

    it "routes to #create" do
      expect(post("/satisfaction")).to route_to("satisfaction_surveys#create")
    end

  end
end