require 'rails_helper'

feature 'Results Event Data Page', js: true, search: true  do
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { sign_in user }

  before do
    Kpi.destroy_all
    Warden.test_mode!
    Kpi.create_global_kpis
    allow_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
  end

  let(:campaign1) { create(:campaign, name: 'First Campaign', company: company) }
  let(:campaign2) { create(:campaign, name: 'Second Campaign', company: company) }

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

  feature 'export as xls' do
    scenario 'should include any custom kpis from all the campaigns' do
      with_resque do
        kpi = create(:kpi, company: company, name: 'A Custom KPI')
        kpi2 = create(:kpi, company: company, name: 'Another KPI')
        campaign1.add_kpi kpi
        campaign2.add_kpi kpi2

        event = build(:approved_event, company: company, campaign: campaign1)
        event.result_for_kpi(kpi).value = '9876'
        event.save

        event = build(:approved_event, company: company, campaign: campaign2)
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
