require 'rails_helper'

feature 'Results Event Data Page', js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = create(:user, company_id: create(:company).id, role_id: create(:role).id)
    @company_user = @user.company_users.first
    @company = @user.companies.first
    Kpi.create_global_kpis
    sign_in @user
    allow_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
  end

  let(:campaign1) { create(:campaign, name: 'First Campaign', company: @company) }
  let(:campaign2) { create(:campaign, name: 'Second Campaign', company: @company) }

  feature 'video tutorial' do
    scenario 'a user can play and dismiss the video tutorial' do
      visit results_event_data_path

      feature_name = 'Getting Started: Event Data Report'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content('The Event Data Report holds all of your post event data')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit results_event_data_path
      expect(page).to have_no_selector('h5', text: feature_name)
    end
  end

  feature 'custom filters' do
    let(:event1) { create(:approved_event, campaign: campaign1, company: @company, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1')) }
    let(:event2) { create(:approved_event, campaign: campaign2, company: @company, start_date: '08/22/2013', end_date: '08/22/2013', start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 2')) }
    let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: @company) }
    let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: @company) }
    let(:kpi1) { create(:kpi, company: @company, name: 'A Custom KPI') }
    let(:kpi2) { create(:kpi, company: @company, name: 'Another KPI') }

    before do
      event1.users << user1
      event2.users << user2
      campaign1.add_kpi kpi1
      campaign2.add_kpi kpi2
      event1.result_for_kpi(kpi1).value = '9876'
      event2.result_for_kpi(kpi2).value = '7654'
      event1.save
      event2.save
      Sunspot.commit
    end

    scenario 'allows to create a new custom filter' do
      visit results_event_data_path

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
        expect(custom_filter.apply_to).to eq('event_data')
        expect(custom_filter.filters).to eq('campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Approved&status%5B%5D=Active')
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('My Custom Filter')
      end
    end

    scenario 'allows to apply custom filters' do
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'event_data', filters: 'campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Approved&status%5B%5D=Active')
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'event_data', filters: 'campaign%5B%5D=' + campaign2.to_param + '&user%5B%5D=' + user2.to_param + '&event_status%5B%5D=Approved&status%5B%5D=Active')

      visit results_event_data_path

      # Using Custom Filter 1
      filter_section('SAVED FILTERS').unicheck('Custom Filter 1')

      within '#event-data-list' do
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

      within '#event-data-list' do
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

      within '#event-data-list' do
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
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 1', apply_to: 'event_data', filters: 'Filters 1')
      cf2 = create(:custom_filter, owner: @company_user, name: 'Custom Filter 2', apply_to: 'event_data', filters: 'Filters 2')
      create(:custom_filter, owner: @company_user, name: 'Custom Filter 3', apply_to: 'event_data', filters: 'Filters 3')

      visit results_event_data_path

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

  feature 'export as xls' do
    scenario 'should include any custom kpis from all the campaigns' do
      with_resque do
        kpi = create(:kpi, company: @company, name: 'A Custom KPI')
        kpi2 = create(:kpi, company: @company, name: 'Another KPI')
        campaign1.add_kpi kpi
        campaign2.add_kpi kpi2

        event = build(:approved_event, company: @company, campaign: campaign1)
        event.result_for_kpi(kpi).value = '9876'
        event.save

        event = build(:approved_event, company: @company, campaign: campaign2)
        event.result_for_kpi(kpi2).value = '7654'
        event.save

        Sunspot.commit
        visit results_event_data_path

        click_button 'Download'

        within visible_modal do
          expect(page).to have_content('We are processing your request, the download will start soon...')
        end
        ensure_modal_was_closed
      end
    end
  end
end
