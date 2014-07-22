require 'spec_helper'

describe Api::V1::SurveysController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { FactoryGirl.create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:place) { FactoryGirl.create(:place) }
  let(:event) {FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)}

  before do
    Kpi.create_global_kpis
  end

  describe "GET 'index'" do
    it "should return failure for invalid authorization token" do
      campaign.update_attribute(:enabled_modules, ['surveys'])
      get :index, company_id: company.to_param, auth_token: 'XXXXXXXXXXXXXXXX', event_id: 100, format: :json
      expect(response.response_code).to eql 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "returns the list of surveys for the event" do
      campaign.update_attribute(:enabled_modules, ['surveys'])
      survey1 = FactoryGirl.create(:survey, event: event)
      survey2 = FactoryGirl.create(:survey, event: event)

      get :index, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result.count.should == 2
      expect(result.first).to include({'id' => survey1.id})
      expect(result.last).to  include({'id' => survey2.id})
    end
    it "should return error if the campaign doest have the surveys module enabled" do
      get :index, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      expect(response.response_code).to eql 403
    end
  end

  describe "GET 'show'" do
    before { campaign.update_attribute(:enabled_modules, ['surveys']) }
    it "should return failure for invalid authorization token" do
      get :show, company_id: company.to_param, auth_token: 'XXXXXXXXXXXXXXXX', event_id: 100, id: 1, format: :json
      expect(response.response_code).to eql 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "returns the list of surveys for the event" do
      survey = FactoryGirl.create(:survey, event: event)

      get :show, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, id: survey.id, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      expect(result).to include({'id' => survey.id})
    end
  end

  describe "POST 'create'" do
    it "should create the new survey" do
      brand1 = FactoryGirl.create(:brand)
      brand2 = FactoryGirl.create(:brand)

      # Assign the surveys module and brands to the campaign
      campaign.update_attributes enabled_modules: ['surveys'],
          survey_brand_ids: [brand1.id, brand2.id]

      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample
      expect {
        post 'create', company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, survey: {
          "surveys_answers_attributes"=>{
            "0"=> {"kpi_id"=>Kpi.gender.id, "answer"=>gender_answer.id},
            "1"=> {"kpi_id"=>Kpi.age.id, "answer"=>age_answer.id},
            "2"=> {"kpi_id"=>Kpi.ethnicity.id, "answer"=>ethnicity_answer.id},
            "3"=> {"brand_id"=>brand1.to_param, "question_id"=>"1", "answer"=>"aware"},
            "4"=> {"brand_id"=>brand2.to_param, "question_id"=>"1", "answer"=>"aware"},
            "5"=> {"brand_id"=>brand1.to_param, "question_id"=>"2", "answer"=>"10"},
            "6"=> {"brand_id"=>brand2.to_param, "question_id"=>"2", "answer"=>"20"},
            "7"=> {"brand_id"=>brand1.to_param, "question_id"=>"3", "answer"=>"2"},
            "8"=> {"brand_id"=>brand2.to_param, "question_id"=>"3", "answer"=>"2"},
            "9"=> {"brand_id"=>brand1.to_param, "question_id"=>"4", "answer"=>"3"},
            "10"=>{"brand_id"=>brand2.to_param, "question_id"=>"4", "answer"=>"4"}
          },
        }, format: :json
      }.to change(Survey, :count).by(1)

      survey = Survey.last
      survey.age.should == age_answer.text
      survey.gender.should == gender_answer.text
      survey.ethnicity.should == ethnicity_answer.text
      response.should be_success

      result = JSON.parse(response.body)

      survey = Survey.last
      survey.event_id.should == event.id
    end

    it "should return error if the campaign doest have the surveys module enabled" do
      brand1 = FactoryGirl.create(:brand)
      brand2 = FactoryGirl.create(:brand)

      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample
      expect {
        post 'create', company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, survey: {
          "surveys_answers_attributes"=>{
            "0"=> {"kpi_id"=>Kpi.gender.id, "answer"=>gender_answer.id},
            "1"=> {"kpi_id"=>Kpi.age.id, "answer"=>age_answer.id},
            "2"=> {"kpi_id"=>Kpi.ethnicity.id, "answer"=>ethnicity_answer.id},
            "3"=> {"brand_id"=>brand1.to_param, "question_id"=>"1", "answer"=>"aware"},
            "4"=> {"brand_id"=>brand2.to_param, "question_id"=>"1", "answer"=>"aware"},
            "5"=> {"brand_id"=>brand1.to_param, "question_id"=>"2", "answer"=>"10"},
            "6"=> {"brand_id"=>brand2.to_param, "question_id"=>"2", "answer"=>"20"},
            "7"=> {"brand_id"=>brand1.to_param, "question_id"=>"3", "answer"=>"2"},
            "8"=> {"brand_id"=>brand2.to_param, "question_id"=>"3", "answer"=>"2"},
            "9"=> {"brand_id"=>brand1.to_param, "question_id"=>"4", "answer"=>"3"},
            "10"=>{"brand_id"=>brand2.to_param, "question_id"=>"4", "answer"=>"4"}
          },
        }, format: :json
      }.to_not change(Survey, :count)
      expect(response.response_code).to eql 403
    end
  end
end
