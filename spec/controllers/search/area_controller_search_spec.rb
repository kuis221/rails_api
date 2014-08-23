require 'rails_helper'

describe AreasController, type: :controller, search: true do
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
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      area_bucket = buckets.select{|b| b['label'] == 'Areas'}.first
      expect(area_bucket['value']).to eq([{"label"=>"<i>Te</i>st Area", "value"=> t.id.to_s, "type"=>"area"}])
    end
  end

  describe "GET 'filters'" do
    it "should return the correct buckets" do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map{|b| b['label']}).to eq(["Active State"])
    end


    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'filters', format: :json

      expect(response).to be_success
      filters = JSON.parse(response.body)

      expect(filters['filters'].map{|b| b['label']}).to eq(["Active State"])
      expect(filters['filters'][0]['items'].count).to eq(2)
      expect(filters['filters'][0]['items'].first['label']).to eq("Active")
      expect(filters['filters'][0]['items'][1]['label']).to eq("Inactive")
    end
  end

end