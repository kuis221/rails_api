require 'rails_helper'

feature 'Results Expenses Page', js: true, search: true  do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company_user) { user.company_users.first }
  let(:campaign1) { create(:campaign, name: 'First Campaign', company: company) }
  let(:campaign2) { create(:campaign, name: 'Second Campaign', company: company) }

  before do
    Kpi.destroy_all
    Warden.test_mode!
    sign_in user
  end
  after { Warden.test_reset! }

  feature 'Event Expenses index', js: true, search: true  do
    scenario 'a user can play and dismiss the video tutorial' do
      visit results_expenses_path

      feature_name = 'GETTING STARTED: EXPENSES REPORT'

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
      event = build(:approved_event, campaign: campaign1, company: company, start_date: '08/21/2013', end_date: '08/21/2013',
                    start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'))
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      event2 = build(:approved_event, campaign: campaign1, company: company, start_date: '08/25/2013', end_date: '08/25/2013',
                     start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'))
      event2.event_expenses.build(name: 'Expense #1 Event #2', event_id: event.id, amount: 20)
      event2.save

      Sunspot.commit
      visit results_expenses_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content('First Campaign')
        expect(page).to have_content('WED Aug 21, 2013, 8:00 PM - 11:00 PM')
        expect(page).to have_content('Place 1, 11 Main St., New York City, 12345')
        expect(page).to have_content('$10.00')
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('First Campaign')
        expect(page).to have_content('SUN Aug 25, 2013, 9:00 AM - 10:00 AM')
        expect(page).to have_content('Place 2, 11 Main St., New York City, 12345')
        expect(page).to have_content('$20.00')
      end
      expect(page).to have_content('TOTAL:$30.00')
    end

    scenario 'clicking on the expense item should redirect the user to the event' do
      event = build(:approved_event, campaign: campaign1, company: company, start_date: '08/21/2013',
                    end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm')
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      Sunspot.commit
      visit results_expenses_path

      click_link("event-link-#{event.id}")

      expect(current_path).to eq(event_path(event.id))
    end
  end

  it_behaves_like 'a list that allow saving custom filters' do

    before do
      create(:campaign, name: 'Campaign 1', company: company)
      create(:campaign, name: 'Campaign 2', company: company)
      create(:area, name: 'Area 1', company: company)
    end

    let(:list_url) { results_expenses_path }

    let(:filters) do
      [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
       { section: 'CAMPAIGNS', item: 'Campaign 2' },
       { section: 'AREAS', item: 'Area 1' },
       { section: 'PEOPLE', item: user.full_name },
       { section: 'ACTIVE STATE', item: 'Inactive' }]
    end
  end

  feature 'export', search: true do
    let(:brand) { create(:brand, name: 'Brand 1', company: company) }

    before do
      create(:approved_event, campaign: campaign1,
             start_date: '08/21/2013', end_date: '08/21/2013',
             start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'),
             event_expenses: [
               build(:event_expense, name: 'Expense #1 Event #1', amount: 10, brand_id: brand.id)])

      create(:approved_event, campaign: campaign1,
             start_date: '08/25/2013', end_date: '08/25/2013',
             start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'),
             event_expenses: [
               build(:event_expense, name: 'Expense #1 Event #2', amount: 20)])

      Sunspot.index Event.all.to_a
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit results_expenses_path

      click_js_button 'Download'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'BRAND', 'VENUE NAME', 'ADDRESS', 'START DATE', 'END DATE', 'EXPENSE', 'DESCRIPTION', 'ACTIVE STATE'],
        [campaign1.name, 'Brand 1', 'Place 1', 'Place 1, 11 Main St., New York City, NY, 12345', '2013-08-21T20:00',
         '2013-08-21T23:00', '10.0', 'Expense #1 Event #1', 'Active'],
        [campaign1.name, nil, 'Place 2', 'Place 2, 11 Main St., New York City, NY, 12345', '2013-08-25T09:00',
         '2013-08-25T10:00', '20.0', 'Expense #1 Event #2', 'Active']
      ])
    end
  end
end
