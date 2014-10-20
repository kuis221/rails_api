require 'rails_helper'

describe Api::V1::SurveysController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:place) { create(:place) }
  let(:event) { create(:approved_event, company: company, campaign: campaign, place: place) }

  before { Kpi.create_global_kpis }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'" do
    it 'returns the list of surveys for the event' do
      campaign.update_attribute(:modules, 'surveys' => {})
      survey1 = create(:survey, event: event)
      survey2 = create(:survey, event: event)

      get :index, event_id: event.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result.first).to include('id' => survey1.id)
      expect(result.last).to include('id' => survey2.id)
    end

    it 'should return error if the campaign doest have the surveys module enabled' do
      get :index, event_id: event.to_param, format: :json
      expect(response.response_code).to eql 403
    end
  end

  describe "GET 'show'" do
    before { campaign.update_attribute(:modules, 'surveys' => {}) }

    it 'returns the list of surveys for the event' do
      survey = create(:survey, event: event)

      get :show, event_id: event.to_param, id: survey.id, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include('id' => survey.id)
    end
  end

  describe "POST 'create'" do
    it 'should create the new survey' do
      brand1 = create(:brand)
      brand2 = create(:brand)

      # Assign the surveys module and brands to the campaign
      campaign.update_attributes(modules: { 'surveys' => {} },
                                 survey_brand_ids: [brand1.id, brand2.id])

      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample
      expect do
        post 'create', event_id: event.to_param, survey: {
          'surveys_answers_attributes' => {
            '0' => { 'kpi_id' => Kpi.gender.id, 'answer' => gender_answer.id },
            '1' => { 'kpi_id' => Kpi.age.id, 'answer' => age_answer.id },
            '2' => { 'kpi_id' => Kpi.ethnicity.id, 'answer' => ethnicity_answer.id },
            '3' => { 'brand_id' => brand1.to_param, 'question_id' => '1', 'answer' => 'aware' },
            '4' => { 'brand_id' => brand2.to_param, 'question_id' => '1', 'answer' => 'aware' },
            '5' => { 'brand_id' => brand1.to_param, 'question_id' => '2', 'answer' => '10' },
            '6' => { 'brand_id' => brand2.to_param, 'question_id' => '2', 'answer' => '20' },
            '7' => { 'brand_id' => brand1.to_param, 'question_id' => '3', 'answer' => '2' },
            '8' => { 'brand_id' => brand2.to_param, 'question_id' => '3', 'answer' => '2' },
            '9' => { 'brand_id' => brand1.to_param, 'question_id' => '4', 'answer' => '3' },
            '10' => { 'brand_id' => brand2.to_param, 'question_id' => '4', 'answer' => '4' }
          }
        }, format: :json
      end.to change(Survey, :count).by(1)

      survey = Survey.last
      expect(survey.age).to eq(age_answer.text)
      expect(survey.gender).to eq(gender_answer.text)
      expect(survey.ethnicity).to eq(ethnicity_answer.text)
      expect(response).to be_success

      survey = Survey.last
      expect(survey.event_id).to eq(event.id)
    end

    it 'should return error if the campaign doest have the surveys module enabled' do
      brand1 = create(:brand)
      brand2 = create(:brand)

      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample
      expect do
        post 'create', event_id: event.to_param, survey: {
          'surveys_answers_attributes' => {
            '0' => { 'kpi_id' => Kpi.gender.id, 'answer' => gender_answer.id },
            '1' => { 'kpi_id' => Kpi.age.id, 'answer' => age_answer.id },
            '2' => { 'kpi_id' => Kpi.ethnicity.id, 'answer' => ethnicity_answer.id },
            '3' => { 'brand_id' => brand1.to_param, 'question_id' => '1', 'answer' => 'aware' },
            '4' => { 'brand_id' => brand2.to_param, 'question_id' => '1', 'answer' => 'aware' },
            '5' => { 'brand_id' => brand1.to_param, 'question_id' => '2', 'answer' => '10' },
            '6' => { 'brand_id' => brand2.to_param, 'question_id' => '2', 'answer' => '20' },
            '7' => { 'brand_id' => brand1.to_param, 'question_id' => '3', 'answer' => '2' },
            '8' => { 'brand_id' => brand2.to_param, 'question_id' => '3', 'answer' => '2' },
            '9' => { 'brand_id' => brand1.to_param, 'question_id' => '4', 'answer' => '3' },
            '10' => { 'brand_id' => brand2.to_param, 'question_id' => '4', 'answer' => '4' }
          }
        }, format: :json
      end.to_not change(Survey, :count)
      expect(response.response_code).to eql 403
    end
  end
end
