require 'spec_helper'

feature "Venues Section", js: true, search: true do
  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  feature "List of venues" do
    scenario "GET index should display a list with the venues" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      venues = []
      with_resque do
        event = FactoryGirl.create(:event, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Benito'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 1000}])

        event = FactoryGirl.create(:event, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Camelas'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 2000}])
      end

      Venue.reindex
      Sunspot.commit

      visit venues_path

      within("ul#venues-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Bar Benito')
          expect(page).to have_selector('div.n_spent', text: '$1,000.00')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Bar Camelas')
          expect(page).to have_selector('div.n_spent', text: '$2,000.00')
        end
      end
    end
  end

  feature "/research/venues/:venue_id", :js => true do
    scenario 'allows the user to add an activity to a Venue' do
      Kpi.create_global_kpis
      venue = FactoryGirl.create(:venue, company: @company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil))
      FactoryGirl.create(:user, company: @company, first_name: 'Juanito', last_name: 'Bazooka')

      activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: @company)
      FactoryGirl.create(:form_field, name: 'Form Field #1', type: 'FormField::Number', fieldable: activity_type, ordering: 1)
      dropdown_field = FactoryGirl.create(:form_field, name: 'Form Field #2', type: 'FormField::Dropdown', fieldable: activity_type, ordering: 2)
      FactoryGirl.create(:form_field_option, name: 'Dropdown option #1', form_field: dropdown_field, ordering: 1)
      FactoryGirl.create(:form_field_option, name: 'Dropdown option #2', form_field: dropdown_field, ordering: 2)

      visit venue_path(venue)

      expect(page).to_not have_content('Activity Type #1')

      click_js_link('New Activity')

      within visible_modal do
        select_from_chosen('Activity Type #1', from: 'Activity type')
        fill_in 'Form Field #1', with: '122'
        select_from_chosen('Dropdown option #2', from: 'Form Field #2')
        fill_in 'Date', with: '12/12/2023'
        select_from_chosen('Juanito Bazooka', from: 'User')
        click_js_button 'Create'
      end

      ensure_modal_was_closed
    end
  end

end