require 'rails_helper'

feature 'Results Surveys Page', js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = create(:user, company_id: create(:company).id, role_id: create(:role).id)
    @company_user = @user.company_users.first
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  let(:campaign1) { create(:campaign, name: 'First Campaign', company: @company) }
  let(:campaign2) { create(:campaign, name: 'Second Campaign', company: @company) }

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

      event1 = build(:approved_event, campaign: campaign1, company: @company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      event1.surveys << survey1
      event1.save

      event2 = build(:approved_event, campaign: campaign1, company: @company, start_date: '08/25/2013', end_date: '08/25/2013', start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'))
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

  feature 'custom filters' do
    let(:event1) { create(:approved_event, campaign: campaign1, company: @company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1')) }
    let(:event2) { create(:approved_event, campaign: campaign2, company: @company, start_date: '08/22/2013', end_date: '08/22/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 2')) }
    let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: @company) }
    let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: @company) }
    let(:survey1) { create(:survey) }
    let(:survey2) { create(:survey) }

    let(:age_answer) { Kpi.age.kpis_segments.sample }
    let(:gender_answer) { Kpi.gender.kpis_segments.sample }
    let(:ethnicity_answer) { Kpi.ethnicity.kpis_segments.sample }

    before do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.surveys)
      campaign2.add_kpi(Kpi.surveys)

      survey1.surveys_answers.build(kpi_id: Kpi.age.id, question_id: 1, answer: age_answer.id)
      survey1.surveys_answers.build(kpi_id: Kpi.gender.id, question_id: 1, answer: gender_answer.id)
      survey2.surveys_answers.build(kpi_id: Kpi.ethnicity.id, question_id: 1, answer: ethnicity_answer.id)
      event1.users << user1
      event2.users << user2
      event1.surveys << survey1
      event2.surveys << survey2
      event1.save
      event2.save
      Sunspot.commit
    end

    scenario 'allows to create a new custom filter' do
      visit results_surveys_path

      filter_section('CAMPAIGNS').unicheck('First Campaign')
      filter_section('PEOPLE').unicheck('Roberto Gomez')
      filter_section('EVENT STATUS').unicheck('Approved')

      click_button 'Save'

      within visible_modal do
        fill_in('Filter name', with: 'My Custom Filter')
        expect do
          click_button 'Save'
          wait_for_ajax
        end.to change(CustomFilter, :count).by(1)

        custom_filter = CustomFilter.last
        expect(custom_filter.owner).to eq(@company_user)
        expect(custom_filter.name).to eq('My Custom Filter')
        expect(custom_filter.apply_to).to eq('surveys')
        expect(custom_filter.filters).to eq(
          'status%5B%5D=Active&campaign%5B%5D=' + campaign1.to_param +
          '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Approved')
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('My Custom Filter')
      end
    end

    scenario 'allows to remove custom filters' do
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'surveys', filters: 'Filters 1')
      cf2 = create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'surveys', filters: 'Filters 2')
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 3', apply_to: 'surveys', filters: 'Filters 3')

      visit results_surveys_path

      find('.settings-for-filters').trigger('click')

      within visible_modal do
        expect(page).to have_content('Custom Filter 1')
        expect(page).to have_content('Custom Filter 2')
        expect(page).to have_content('Custom Filter 3')

        expect do
          hover_and_click('#saved-filters-container #custom-filter-' + cf2.id.to_s, 'Remove Custom Filter')
          wait_for_ajax
        end.to change(CustomFilter, :count).by(-1)

        expect(page).to have_content('Custom Filter 1')
        expect(page).to_not have_content('Custom Filter 2')
        expect(page).to have_content('Custom Filter 3')

        click_button 'Done'
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('Custom Filter 1')
        expect(page).to_not have_content('Custom Filter 2')
        expect(page).to have_content('Custom Filter 3')
      end
    end
  end
end
