require 'spec_helper'

describe CampaignsController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.commit
  end

  describe "GET 'autocomplete'" do

    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Campaigns', 'Brands', 'Places', 'People']
    end

    it "should return the users in the People Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'gu'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the teams in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'sp'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}]
    end

    it "should return the teams and users in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Valladolid', company_id: @company.id)
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'va'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
    end

    it "should return the brands in the Brands Bucket" do
      brand = FactoryGirl.create(:brand, name: 'Cacique')
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
      brands_bucket['value'].should == [{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}]
    end

    it "should return the venues in the Places Bucket" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      venue = FactoryGirl.create(:venue, company_id: @company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'autocomplete', q: 'mot'
      response.should be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
      places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}]
    end
  end

  describe "GET 'filters'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'filters', format: :json
      response.should be_success

      filters = JSON.parse(response.body)
      filters['filters'].map{|b| b['label']}.should == ["Brands", "Brand Portfolios", "People", "Active State"]
    end
  end


  describe "POST 'find_similar_kpi'" do
    it "should return empty if there are no kpis" do
      get 'find_similar_kpi', name: 'brands'
      results = JSON.parse(response.body)
      results.should be_empty
    end

    it "should return the kpi if there is one with the same name" do
      FactoryGirl.create(:kpi, name: 'Number Events', company: @company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Number Events'
      results = JSON.parse(response.body)
      results.should_not be_empty

      results.length.should == 1
    end

    it "should return the kpi if there is one with a similar name" do
      FactoryGirl.create(:kpi, name: 'Number Events', company: @company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Number of Events'
      results = JSON.parse(response.body)
      results.should_not be_empty

      results.length.should == 1
    end

    it "should return the kpi if there is one with the same word but in singular" do
      FactoryGirl.create(:kpi, name: 'Events', company: @company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Event'
      results = JSON.parse(response.body)
      results.should_not be_empty

      results.length.should == 1
    end
  end

end
