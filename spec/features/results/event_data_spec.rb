require 'spec_helper'

feature "Results Event Data Page", js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    Kpi.create_global_kpis
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }

  feature "export as xls" do
    scenario "a user can play and dismiss the video tutorial" do
      visit results_event_data_path

      feature_name = 'Getting Started: Event Data Report'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content("The Event Data Report holds all of your post event data")
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

    scenario "should include any custom kpis from all the campaigns" do
      with_resque do
        kpi = FactoryGirl.create(:kpi, company: @company, name: 'A Custom KPI')
        kpi2 = FactoryGirl.create(:kpi, company: @company, name: 'Another KPI')
        campaign2 = FactoryGirl.create(:campaign, company: @company)
        campaign.add_kpi kpi
        campaign2.add_kpi kpi2

        event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = '9876'
        event.save

        event = FactoryGirl.build(:approved_event, company: @company, campaign: campaign2)
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