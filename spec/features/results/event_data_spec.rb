require 'rails_helper'

feature 'Results Event Data Page', js: true, search: true  do
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:campaign) { create(:campaign, name: 'First Campaign', company: company) }

  before { sign_in user }

  before do
    allow_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
  end

  feature 'video tutorial' do
    scenario 'a user can play and dismiss the video tutorial' do
      visit results_event_data_path

      feature_name = 'GETTING STARTED: EVENT DATA REPORT'

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

  it_behaves_like 'a list that allow saving custom filters' do
    before do
      create(:campaign, name: 'Campaign 1', company: company)
      create(:campaign, name: 'Campaign 2', company: company)
      create(:area, name: 'Area 1', company: company)
    end

    let(:list_url) { results_event_data_path }

    let(:filters) do
      [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
       { section: 'CAMPAIGNS', item: 'Campaign 2' },
       { section: 'AREAS', item: 'Area 1' },
       { section: 'PEOPLE', item: user.full_name },
       { section: 'ACTIVE STATE', item: 'Inactive' }]
    end
  end

  feature 'export as CSV' do
    scenario 'should include any custom kpis from all the campaigns' do
      with_resque do
        field = create(:form_field_number, name: 'My Numeric Field', fieldable: campaign)
        event = create(:approved_event, company: company, campaign: campaign)
        event.results_for([field]).first.value = '9876'
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
