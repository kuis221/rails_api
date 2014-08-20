require 'rails_helper'

describe DayPartsController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map{|b| b['label']}).to eq(['Day parts'])
    end

    it "should return the brands in the Day parts Bucket" do
      day_part = FactoryGirl.create(:day_part, name: 'Part 1', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'par'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      day_parts_bucket = buckets.select{|b| b['label'] == 'Day parts'}.first
      expect(day_parts_bucket['value']).to eq([{"label"=>"<i>Par</i>t 1", "value"=>day_part.id.to_s, "type"=>"day_part"}])
    end
  end

  describe "GET 'filters'" do
    it "should return the correct filters in the right order" do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map{|b| b['label']}).to eq(["Active State"])
    end
  end
end