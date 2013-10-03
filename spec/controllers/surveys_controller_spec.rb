require 'spec_helper'

describe SurveysController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company

    Kpi.create_global_kpis
    campaign.assign_all_global_kpis
  end

  let(:campaign) {FactoryGirl.create(:campaign, company: @company)}
  let(:event) {FactoryGirl.create(:event, company: @company, campaign: campaign)}

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', event_id: event.to_param, format: :js
      response.should render_template('new')
      response.should render_template('form')
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', event_id: event.to_param, format: :js
      response.should be_success
      response.should render_template('create')
    end

    it "should not render form_dialog if no errors" do
      brand1 = FactoryGirl.create(:brand)
      brand2 = FactoryGirl.create(:brand)
      lambda {
        post 'create', event_id: event.to_param, survey: {
          "surveys_answers_attributes"=>{
            "0"=>{"kpi_id"=>Kpi.gender.id, "question_id"=>"1", "answer"=>Kpi.gender.kpis_segments.sample.id},
            "1"=>{"kpi_id"=>Kpi.age.id, "question_id"=>"1", "answer"=>Kpi.age.kpis_segments.sample.id},
            "2"=>{"kpi_id"=>Kpi.ethnicity.id, "question_id"=>"1", "answer"=>Kpi.ethnicity.kpis_segments.sample.id},
            "3"=>{"brand_id"=>brand1.to_param, "question_id"=>"1", "answer"=>"aware"},
            "4"=>{"brand_id"=>brand2.to_param, "question_id"=>"1", "answer"=>"aware"},
            "5"=>{"brand_id"=>brand1.to_param, "question_id"=>"2", "answer"=>""},
            "6"=>{"brand_id"=>brand2.to_param, "question_id"=>"2", "answer"=>""},
            "7"=>{"brand_id"=>brand1.to_param, "question_id"=>"3", "answer"=>"2"},
            "8"=>{"brand_id"=>brand2.to_param, "question_id"=>"3", "answer"=>"2"},
            "9"=>{"brand_id"=>brand1.to_param, "question_id"=>"4", "answer"=>"3"},
            "10"=>{"brand_id"=>brand2.to_param, "question_id"=>"4", "answer"=>"4"}
          },
        }, format: :js
      }.should change(Survey, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      survey = Survey.last
      survey.event_id.should == event.id
    end
  end

  describe "GET 'deactivate'" do
    let(:survey){ FactoryGirl.create(:survey, event: event) }

    it "deactivates an active survey" do
      survey.update_attribute(:active, true)
      get 'deactivate', event_id: survey.event_id, id: survey.to_param, format: :js
      response.should be_success
      survey.reload.active?.should be_false
    end

    it "activates an inactive survey" do
      survey.update_attribute(:active, false)
      get 'activate', event_id: survey.event_id, id: survey.to_param, format: :js
      response.should be_success
      survey.reload.active?.should be_true
    end
  end
end
