require 'rails_helper'

feature 'Results Expenses Page', js: true, search: true  do

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

  feature 'Event Expenses index', js: true, search: true  do
    scenario 'a user can play and dismiss the video tutorial' do
      visit results_expenses_path

      feature_name = 'Getting Started: Expenses Report'

      expect(page).to have_content(feature_name)
      expect(page).to have_content('Keep track of your event and campaign expenses')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit results_expenses_path
      expect(page).to have_no_content(feature_name)
    end

    scenario 'GET index should display a table with the expenses' do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.expenses)
      event = build(:approved_event, campaign: campaign1, company: @company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      event2 = build(:approved_event, campaign: campaign1, company: @company, start_date: '08/25/2013', end_date: '08/25/2013', start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'))
      event2.event_expenses.build(name: 'Expense #1 Event #2', event_id: event.id, amount: 20)
      event2.save

      Sunspot.commit
      visit results_expenses_path

      within('ul#expenses-list') do
        # First Row
        within('li:nth-child(1)') do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('WED Aug 21, 2013, 8:00 PM - 11:00 PM')
          expect(page).to have_content('Place 1, New York City, NY, 12345')
          expect(page).to have_content('$10.00')
        end
        # Second Row
        within('li:nth-child(2)') do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('SUN Aug 25, 2013, 9:00 AM - 10:00 AM')
          expect(page).to have_content('Place 2, New York City, NY, 12345')
          expect(page).to have_content('$20.00')
        end
      end
      expect(page).to have_content('TOTAL:$30.00')
    end

    scenario 'clicking on the expense item should redirect the user to the event' do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.expenses)
      event = build(:approved_event, campaign: campaign1, company: @company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm')
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      Sunspot.commit
      visit results_expenses_path

      click_link("event-link-#{event.id}")

      expect(current_path).to eq(event_path(event.id))
    end
  end

  feature 'custom filters' do
    let(:event1) { create(:approved_event, campaign: campaign1, company: @company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1')) }
    let(:event2) { create(:approved_event, campaign: campaign2, company: @company, start_date: '08/22/2013', end_date: '08/22/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 2')) }
    let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: @company) }
    let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: @company) }

    before do
      Kpi.create_global_kpis
      campaign1.add_kpi(Kpi.expenses)
      campaign2.add_kpi(Kpi.expenses)
      event1.users << user1
      event2.users << user2
      event1.event_expenses.build(name: 'Expense #1 Event #1', event_id: event1.id, amount: 10)
      event2.event_expenses.build(name: 'Expense #1 Event #2', event_id: event2.id, amount: 20)
      event1.save
      event2.save
      Sunspot.commit
    end

    scenario 'allows to create a new custom filter' do
      visit results_expenses_path

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
        expect(custom_filter.apply_to).to eq('results_expenses')
        expect(custom_filter.filters).to eq('campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Approved&status%5B%5D=Active')
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('My Custom Filter')
      end
    end

    scenario 'allows to apply custom filters' do
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'results_expenses', filters: 'campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Approved&status%5B%5D=Active')
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'results_expenses', filters: 'campaign%5B%5D=' + campaign2.to_param + '&user%5B%5D=' + user2.to_param + '&event_status%5B%5D=Approved&status%5B%5D=Active')

      visit results_expenses_path

      # Using Custom Filter 1
      filter_section('SAVED FILTERS').unicheck('Custom Filter 1')

      within '#expenses-list' do
        expect(page).to have_content('First Campaign')
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

      # Using Custom Filter 2 should update results and checked/unchecked checkboxes
      filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

      within '#expenses-list' do
        expect(page).to have_content('Second Campaign')
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

      # Using Custom Filter 2 again should reset filters
      filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

      within '#expenses-list' do
        expect(page).to have_content('First Campaign')
        expect(page).to have_content('Second Campaign')
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

    scenario 'allows to remove custom filters' do
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'results_expenses', filters: 'Filters 1')
      cf2 = create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'results_expenses', filters: 'Filters 2')
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 3', apply_to: 'results_expenses', filters: 'Filters 3')

      visit results_expenses_path

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
