require 'rails_helper'

describe Results::SurveysController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'queue the job for export the list' do
      expect do
        xhr :get, :index, format: :csv
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
    end
  end

  describe "GET 'items'" do
    it 'should return http success' do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('results/surveys/items')
    end
  end

  describe "GET 'list_export'", search: true do
    let(:campaign) { create(:campaign, company: @company, name: 'Test Campaign FY01') }

    before do
      Kpi.create_global_kpis
    end

    it 'should return an empty csv with the correct headers' do
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['DESCRIPTION', 'CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'EVENT START DATE', 'EVENT END DATE', 'SURVEY CREATED DATE']
      ])
    end

    it 'should return an empty csv with the correct headers' do
      campaign.add_kpi(Kpi.surveys)
      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample

      survey = create(:survey, created_at: Time.zone.local(2013, 8, 21, 22, 30))
      survey.surveys_answers.build(kpi_id: Kpi.age.id, question_id: 1, answer: age_answer.id)
      survey.surveys_answers.build(kpi_id: Kpi.gender.id, question_id: 1, answer: gender_answer.id)
      survey.surveys_answers.build(kpi_id: Kpi.ethnicity.id, question_id: 1, answer: ethnicity_answer.id)

      event = build(:approved_event,
                    campaign: campaign, start_date: '08/21/2013', end_date: '08/21/2013',
                    start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      event.surveys << survey
      event.save
      Sunspot.commit

      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['DESCRIPTION', 'CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'EVENT START DATE', 'EVENT END DATE', 'SURVEY CREATED DATE'],
        [age_answer.text + ' year old,' + ethnicity_answer.text + ',' + gender_answer.text, 'Test Campaign FY01', 'Place 1',
         'Place 1, 11 Main St., New York City, NY, 12345', '08/21/2013 08:00PM', '08/21/2013 11:00PM', '08/21/2013 10:30PM']
      ])
    end
  end
end
