require 'rails_helper'

feature "Results Surveys Page", js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company_user = @user.company_users.first
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  let(:campaign1){ FactoryGirl.create(:campaign, name: 'First Campaign', company: @company) }
  let(:campaign2){ FactoryGirl.create(:campaign, name: 'Second Campaign', company: @company) }

  feature "Surveys index", js: true, search: true  do
    scenario "GET index should display a table with the surveys" do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.surveys)
      age_answer = Kpi.age.kpis_segments.sample
      gender_answer = Kpi.gender.kpis_segments.sample
      ethnicity_answer = Kpi.ethnicity.kpis_segments.sample

      survey1 = FactoryGirl.create(:survey)
      survey1.surveys_answers.build(kpi_id: Kpi.age.id, question_id: 1, answer: age_answer.id)
      survey1.surveys_answers.build(kpi_id: Kpi.gender.id, question_id: 1, answer: gender_answer.id)
      survey2 = FactoryGirl.create(:survey)
      survey2.surveys_answers.build(kpi_id: Kpi.ethnicity.id, question_id: 1, answer: ethnicity_answer.id)

      event1 = FactoryGirl.build(:approved_event, campaign: campaign1, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm', place: FactoryGirl.create(:place, name: 'Place 1'))
      event1.surveys << survey1
      event1.save

      event2 = FactoryGirl.build(:approved_event, campaign: campaign1, company: @company, start_date: "08/25/2013", end_date: "08/25/2013", start_time: '9:00am', end_time: '10:00am', place: FactoryGirl.create(:place, name: 'Place 2'))
      event2.surveys << survey2
      event2.save

      Sunspot.commit
      visit results_surveys_path

      within("ul#surveys-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content(age_answer.text)
          expect(page).to have_content(gender_answer.text)
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content(ethnicity_answer.text)
        end
      end
    end
  end

  feature "custom filters" do
    let(:event1) { FactoryGirl.create(:approved_event, campaign: campaign1, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm', place: FactoryGirl.create(:place, name: 'Place 1')) }
    let(:event2) { FactoryGirl.create(:approved_event, campaign: campaign2, company: @company, start_date: "08/22/2013", end_date: "08/22/2013", start_time: '8:00pm', end_time: '11:00pm', place: FactoryGirl.create(:place, name: 'Place 2')) }
    let(:user1) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: @company) }
    let(:user2) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Mario', last_name: 'Moreno'), company: @company) }
    let(:survey1){ FactoryGirl.create(:survey) }
    let(:survey2){ FactoryGirl.create(:survey) }

    before do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.surveys)
      campaign2.add_kpi(Kpi.surveys)
      @age_answer = Kpi.age.kpis_segments.sample
      @gender_answer = Kpi.gender.kpis_segments.sample
      @ethnicity_answer = Kpi.ethnicity.kpis_segments.sample

      survey1.surveys_answers.build(kpi_id: Kpi.age.id, question_id: 1, answer: @age_answer.id)
      survey1.surveys_answers.build(kpi_id: Kpi.gender.id, question_id: 1, answer: @gender_answer.id)
      survey2.surveys_answers.build(kpi_id: Kpi.ethnicity.id, question_id: 1, answer: @ethnicity_answer.id)
      event1.users << user1
      event2.users << user2
      event1.surveys << survey1
      event2.surveys << survey2
      event1.save
      event2.save
      Sunspot.commit
    end

    scenario "allows to create a new custom filter" do
      visit results_surveys_path

      filter_section('CAMPAIGNS').unicheck('First Campaign')
      filter_section('PEOPLE').unicheck('Roberto Gomez')
      filter_section('EVENT STATUS').unicheck('Approved')

      click_button 'Save'

      within visible_modal do
        fill_in('Filter name', with: 'My Custom Filter')
        expect {
          click_button 'Save'
          wait_for_ajax
        }.to change(CustomFilter, :count).by(1)

        custom_filter = CustomFilter.last
        expect(custom_filter.owner).to eq(@company_user)
        expect(custom_filter.name).to eq('My Custom Filter')
        expect(custom_filter.apply_to).to eq('surveys')
        expect(custom_filter.filters).to eq('campaign%5B%5D='+campaign1.to_param+'&user%5B%5D='+user1.to_param+'&event_status%5B%5D=Approved&status%5B%5D=Active')
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('My Custom Filter')
      end
    end

    scenario "allows to apply custom filters" do
      FactoryGirl.create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'surveys', filters: 'campaign%5B%5D='+campaign1.to_param+'&user%5B%5D='+user1.to_param+'&event_status%5B%5D=Approved&status%5B%5D=Active')
      FactoryGirl.create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'surveys', filters: 'campaign%5B%5D='+campaign2.to_param+'&user%5B%5D='+user2.to_param+'&event_status%5B%5D=Approved&status%5B%5D=Active')

      visit results_surveys_path

      #Using Custom Filter 1
      filter_section('SAVED FILTERS').unicheck('Custom Filter 1')

      within '#surveys-list' do
        expect(page).to have_content(@age_answer.text)
        expect(page).to have_content(@gender_answer.text)
      end

      within '.form-facet-filters' do
        expect(find_field('First Campaign')['checked']).to be_truthy
        expect(find_field('Second Campaign')['checked']).to be_falsey
        expect(find_field('Roberto Gomez')['checked']).to be_truthy
        expect(find_field('Mario Moreno')['checked']).to be_falsey
        expect(find_field('Approved')['checked']).to be_truthy
        expect(find_field('Active')['checked']).to be_truthy
        expect(find_field('Inactive')['checked']).to be_falsey
        expect(find_field('Custom Filter 1')['checked']).to be_truthy
        expect(find_field('Custom Filter 2')['checked']).to be_falsey
      end

      #Using Custom Filter 2 should update results and checked/unchecked checkboxes
      filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

      within '#surveys-list' do
        expect(page).to have_content(@ethnicity_answer.text)
      end

      within '.form-facet-filters' do
        expect(find_field('First Campaign')['checked']).to be_falsey
        expect(find_field('Second Campaign')['checked']).to be_truthy
        expect(find_field('Roberto Gomez')['checked']).to be_falsey
        expect(find_field('Mario Moreno')['checked']).to be_truthy
        expect(find_field('Approved')['checked']).to be_truthy
        expect(find_field('Active')['checked']).to be_truthy
        expect(find_field('Inactive')['checked']).to be_falsey
        expect(find_field('Custom Filter 1')['checked']).to be_falsey
        expect(find_field('Custom Filter 2')['checked']).to be_truthy
      end

      #Using Custom Filter 2 again should reset filters
      filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

      within '#surveys-list' do
        expect(page).to have_content(@age_answer.text)
        expect(page).to have_content(@gender_answer.text)
        expect(page).to have_content(@ethnicity_answer.text)
      end

      within '.form-facet-filters' do
        expect(find_field('First Campaign')['checked']).to be_falsey
        expect(find_field('Second Campaign')['checked']).to be_falsey
        expect(find_field('Roberto Gomez')['checked']).to be_falsey
        expect(find_field('Mario Moreno')['checked']).to be_falsey
        expect(find_field('Approved')['checked']).to be_falsey
        expect(find_field('Active')['checked']).to be_truthy
        expect(find_field('Inactive')['checked']).to be_falsey
        expect(find_field('Custom Filter 1')['checked']).to be_falsey
        expect(find_field('Custom Filter 2')['checked']).to be_falsey
      end
    end

    scenario "allows to remove custom filters" do
      FactoryGirl.create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'surveys', filters: 'Filters 1')
      cf2 = FactoryGirl.create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'surveys', filters: 'Filters 2')
      FactoryGirl.create(:custom_filter, owner: @company_user, name: 'Custom Filter 3', apply_to: 'surveys', filters: 'Filters 3')

      visit results_surveys_path

      find('.settings-for-filters').trigger('click')

      within visible_modal do
        expect(page).to have_content('Custom Filter 1')
        expect(page).to have_content('Custom Filter 2')
        expect(page).to have_content('Custom Filter 3')

        expect {
          hover_and_click('#saved-filters-container #custom-filter-'+cf2.id.to_s, 'Remove Custom Filter')
          wait_for_ajax
        }.to change(CustomFilter, :count).by(-1)

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