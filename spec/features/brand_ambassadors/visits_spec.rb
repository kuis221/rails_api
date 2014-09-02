require 'rails_helper'

feature "Brand Ambassadors Visits" do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
    Company.current = company
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can view the list of visits' do
    scenario "a list of visits is displayed" do
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: '02/01/2014', end_date: '02/02/2014',
        name: 'Visit1', company_user: company_user, active: true)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: '02/02/2014', end_date: '02/03/2014',
        name: 'Visit2', company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path

      within("ul#visits-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Visit1')
          expect(page).to have_content(company_user.full_name)
          expect(page).to have_content('SAT Feb 1')
          expect(page).to have_content('SUN Feb 2')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Visit2')
          expect(page).to have_content(company_user.full_name)
          expect(page).to have_content('SUN Feb 2')
          expect(page).to have_content('MON Feb 3')
        end
      end
    end
  end

  shared_examples_for 'a user that can view the calendar of visits' do
    scenario "a calendar of visits is displayed" do
      month_number = Time.now.strftime('%m')
      month_name = Time.now.strftime('%B')
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: "#{month_number}/15/2014", end_date: "#{month_number}/16/2014",
        name: 'Visit1', company_user: company_user, active: true)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: "#{month_number}/16/2014", end_date: "#{month_number}/18/2014",
        name: 'Visit2', company_user: company_user, active: true)
      Sunspot.commit

      visit brand_ambassadors_root_path

      click_link "Calendar View"

      wait_for_ajax
      within("div#calendar-view") do
        expect(find('.fc-toolbar .fc-left h2')).to have_content("#{month_name}, 2014")
        expect(page).to have_content 'Visit2 Test User'
        expect(page).to have_content 'Visit1 Test User'
      end
    end
  end

  shared_examples_for 'a user that can create visits' do
    scenario 'allows the user to create a new visit' do
      visit brand_ambassadors_root_path

      click_js_button 'New Visit'

      within visible_modal do
        fill_in 'Name', with: 'new visit name'
        fill_in 'Start date', with: '01/23/2014'
        fill_in 'End date', with: '01/24/2014'
        select_from_chosen(company_user.name, from: 'Employee')
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new visit name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new visit name')
      expect(page).to have_content(company_user.name)
    end
  end

  shared_examples_for 'a user that can edit visits' do
    scenario 'allows the user to edit a visit' do
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: '02/01/2014', end_date: '02/02/2014',
        name: 'Visit1', company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path

      within("ul#visits-list") do
        click_js_link('Edit')
      end

      within visible_modal do
        fill_in 'Name', with: 'new visit name'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within("ul#visits-list") do
        expect(page).to have_content 'new visit name'
      end
    end
  end

  shared_examples_for 'a user that can deactivate visits' do
    scenario "can deactivate a visit and it's removed from the view" do
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: '02/01/2014', end_date: '02/02/2014',
        name: 'Visit1', company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path

      within("ul#visits-list") do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this visit?'

      within("ul#visits-list") do
        expect(page).to have_no_selector('li')
      end
    end
  end

  shared_examples_for 'a user that can view visits details' do
    let(:campaign){ FactoryGirl.create(:campaign, company: company, name: 'ABSOLUT Vodka') }

    scenario "allows to create a new event" do
      FactoryGirl.create(:company_user, company: company,
        user: FactoryGirl.create(:user, first_name: 'Other', last_name: 'User'))
      campaign.save

      ba_visit = FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: company_user)

      visit brand_ambassadors_visit_path(ba_visit)

      within "#visit-events" do
        click_button 'Create'
      end

      within visible_modal do
        expect(page).to have_content(company_user.full_name)
        select_from_chosen('ABSOLUT Vodka', from: 'Campaign')
        select_from_chosen('Other User', from: 'Event staff')
        fill_in 'Description', with: 'some event description'
        click_button 'Create'
      end
      ensure_modal_was_closed
      expect(page).to have_content('ABSOLUT Vodka')
      expect(page).to have_content('some event description')
      within '#event-team-members' do
        expect(page).to have_content('Other User')
      end

      click_link 'You are viewing event details. Click to close.'

      expect(current_path).to eq(brand_ambassadors_visit_path(ba_visit))
      within "#visit-events" do
        expect(page).to have_content('BSOLUT Vodka')
      end
    end
  end

  shared_examples_for 'a user that can view visits details and deactivate visits' do
    scenario "can activate/deactivate a visit from the details view" do
      ba_visit = FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: company_user)

      visit brand_ambassadors_visit_path(ba_visit)

      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt "Are you sure you want to deactivate this visit?"

      within('.links-data') do
        click_js_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end
  end

  feature "Non Admin User", js: true, search: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that can view the list of visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can deactivate visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can edit visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:update, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can create visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:create, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can view the calendar of visits" do
      let(:permissions) { [[:calendar, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can view visits details and deactivate visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']]}
    end
  end

  feature "Admin User", js: true, search: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can view the list of visits"
    it_behaves_like "a user that can deactivate visits"
    it_behaves_like "a user that can edit visits"
    it_behaves_like "a user that can create visits"
    it_behaves_like "a user that can view visits details"
    it_behaves_like "a user that can view visits details and deactivate visits"
  end
end
