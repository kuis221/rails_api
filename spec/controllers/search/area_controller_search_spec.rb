require 'spec_helper'

describe AreasController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end
  
  let(:area){ FactoryGirl.create(:area, company: @company) }
  
  describe "GET 'autocomplete'" do
    it "should return the areas in the Area Bucket" do
      t = FactoryGirl.create(:area, name: 'Test Area', description: 'Test Area description', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'te'
      response.should be_success
      
      buckets = JSON.parse(response.body)
      area_bucket = buckets.select{|b| b['label'] == 'Areas'}.first
      area_bucket['value'].should == [{"label"=>"<i>Te</i>st Area", "value"=> t.id.to_s, "type"=>"area"}]
    end
  end
  
  describe "GET 'filters'" do
    it "should return the correct buckets" do
      Sunspot.commit
      get 'filters', format: :json
      response.should be_success

      filters = JSON.parse(response.body)
      filters['filters'].map{|b| b['label']}.should == ["Active State"]
    end


    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'filters', format: :json

      response.should be_success
      filters = JSON.parse(response.body)

      filters['filters'].map{|b| b['label']}.should == ["Active State"]
      filters['filters'][0]['items'].count.should == 2
      filters['filters'][0]['items'].first['label'].should == "Active"
      filters['filters'][0]['items'][1]['label'].should == "Inactive"
    end
  end
  
end