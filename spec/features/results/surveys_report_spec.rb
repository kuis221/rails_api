require 'rails_helper'

feature 'Results Surveys Page', js: true, search: true  do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after { Warden.test_reset! }

  let(:campaign1) { create(:campaign, name: 'First Campaign', company: company) }
  let(:campaign2) { create(:campaign, name: 'Second Campaign', company: company) }

  feature 'Surveys index', js: true, search: true  do
    scenario 'GET index should display a table with the surveys' do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.surveys)
      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample

      survey1 = create(:survey)
      survey1.surveys_answers.build(kpi_id: Kpi.age.id, question_id: 1, answer: age_answer.id)
      survey1.surveys_answers.build(kpi_id: Kpi.gender.id, question_id: 1, answer: gender_answer.id)
      survey2 = create(:survey)
      survey2.surveys_answers.build(kpi_id: Kpi.ethnicity.id, question_id: 1, answer: ethnicity_answer.id)

      event1 = build(:approved_event,
                     campaign: campaign1, start_date: '08/21/2013', end_date: '08/21/2013',
                     start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      event1.surveys << survey1
      event1.save

      event2 = build(:approved_event,
                     campaign: campaign1, start_date: '08/25/2013', end_date: '08/25/2013',
                     start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'))
      event2.surveys << survey2
      event2.save

      Sunspot.commit
      visit results_surveys_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content(age_answer.text)
        expect(page).to have_content(gender_answer.text)
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content(ethnicity_answer.text)
      end
    end
  end

  it_behaves_like 'a list that allow saving custom filters' do

    before do
      create(:campaign, name: 'Campaign 1', company: company)
      create(:campaign, name: 'Campaign 2', company: company)
      create(:area, name: 'Area 1', company: company)
    end

    let(:list_url) { results_surveys_path }

    let(:filters) do
      [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
       { section: 'CAMPAIGNS', item: 'Campaign 2' },
       { section: 'AREAS', item: 'Area 1' },
       { section: 'PEOPLE', item: user.full_name },
       { section: 'ACTIVE STATE', item: 'Inactive' }]
    end
  end

  feature 'export', search: true do
    scenario 'should be able to export as CSV' do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.surveys)
      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample

      survey = create(:survey, created_at: Time.zone.local(2013, 8, 21, 22, 30))
      survey.surveys_answers.build(kpi_id: Kpi.age.id, question_id: 1, answer: age_answer.id)
      survey.surveys_answers.build(kpi_id: Kpi.gender.id, question_id: 1, answer: gender_answer.id)
      survey.surveys_answers.build(kpi_id: Kpi.ethnicity.id, question_id: 1, answer: ethnicity_answer.id)

      event = build(:approved_event,
                    campaign: campaign1, start_date: '08/21/2013', end_date: '08/21/2013',
                    start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      event.surveys << survey
      event.save
      Sunspot.commit

      visit results_surveys_path

      click_js_button 'Download'

      wait_for_export_to_complete

      expect(ListExport.last).to have_rows([
        ['DESCRIPTION', 'CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'EVENT START DATE', 'EVENT END DATE', 'SURVEY CREATED DATE'],
        [age_answer.text + ' year old,' + ethnicity_answer.text + ',' + gender_answer.text, 'First Campaign', 'Place 1',
         'Place 1, 11 Main St., New York City, NY, 12345', '08/21/2013 08:00PM', '08/21/2013 11:00PM', '08/21/2013 10:30PM']
      ])
    end
  end
end
