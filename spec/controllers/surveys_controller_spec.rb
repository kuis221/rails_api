require 'spec_helper'

describe SurveysController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company

    Kpi.create_global_kpis
  end

  let(:campaign) {FactoryGirl.create(:campaign, company: @company)}
  let(:event) {FactoryGirl.create(:event, company: @company, campaign: campaign)}

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', event_id: event.to_param, format: :js
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      xhr :post, 'create', event_id: event.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('create')
    end

    it "should not render form_dialog if no errors" do
      brand1 = FactoryGirl.create(:brand, company: @company)
      brand2 = FactoryGirl.create(:brand, company: @company)

      campaign.modules = {'surveys' => {}}
      campaign.survey_brand_ids = [brand1.id, brand2.id]
      campaign.save

      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample
      expect {
        post 'create', event_id: event.to_param, survey: {
          "surveys_answers_attributes"=>{
            "0"=>{"kpi_id"=>Kpi.gender.id, "question_id"=>"1", "answer"=>gender_answer.id},
            "1"=>{"kpi_id"=>Kpi.age.id, "question_id"=>"1", "answer"=>age_answer.id},
            "2"=>{"kpi_id"=>Kpi.ethnicity.id, "question_id"=>"1", "answer"=>ethnicity_answer.id},
            "3"=>{"brand_id"=>brand1.to_param, "question_id"=>"1", "answer"=>"aware"},
            "4"=>{"brand_id"=>brand2.to_param, "question_id"=>"1", "answer"=>"aware"},
            "5"=>{"brand_id"=>brand1.to_param, "question_id"=>"2", "answer"=>"10"},
            "6"=>{"brand_id"=>brand2.to_param, "question_id"=>"2", "answer"=>"20"},
            "7"=>{"brand_id"=>brand1.to_param, "question_id"=>"3", "answer"=>"2"},
            "8"=>{"brand_id"=>brand2.to_param, "question_id"=>"3", "answer"=>"2"},
            "9"=>{"brand_id"=>brand1.to_param, "question_id"=>"4", "answer"=>"3"},
            "10"=>{"brand_id"=>brand2.to_param, "question_id"=>"4", "answer"=>"4"}
          },
        }, format: :js
      }.to change(Survey, :count).by(1)

      survey = Survey.last
      expect(survey.age).to eq(age_answer.text)
      expect(survey.gender).to eq(gender_answer.text)
      expect(survey.ethnicity).to eq(ethnicity_answer.text)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      survey = Survey.last
      expect(survey.event_id).to eq(event.id)
    end
  end

  describe "PUT 'update'" do
    let(:survey){ FactoryGirl.create(:survey, event: event) }

    it "should correcly update the attribtes" do
      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample
      put 'update', event_id: event.to_param, id: survey.id, survey: {
        "surveys_answers_attributes"=>{
          "0"=>{"kpi_id"=>Kpi.gender.id, "question_id"=>"1", "answer"=>gender_answer.id},
          "1"=>{"kpi_id"=>Kpi.age.id, "question_id"=>"1", "answer"=>age_answer.id},
          "2"=>{"kpi_id"=>Kpi.ethnicity.id, "question_id"=>"1", "answer"=>ethnicity_answer.id}
        },
      }, format: :js

      expect(survey.age).to eq(age_answer.text)
      expect(survey.gender).to eq(gender_answer.text)
      expect(survey.ethnicity).to eq(ethnicity_answer.text)
    end
  end

  describe "GET 'deactivate'" do
    let(:survey){ FactoryGirl.create(:survey, event: event) }

    it "deactivates an active survey" do
      survey.update_attribute(:active, true)
      xhr :get, 'deactivate', event_id: survey.event_id, id: survey.to_param, format: :js
      expect(response).to be_success
      expect(survey.reload.active?).to be_falsey
    end

    it "activates an inactive survey" do
      survey.update_attribute(:active, false)
      xhr :get, 'activate', event_id: survey.event_id, id: survey.to_param, format: :js
      expect(response).to be_success
      expect(survey.reload.active?).to be_truthy
    end
  end
end
