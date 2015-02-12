require 'rails_helper'

feature 'Attendance', js: true, search: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, modules: { 'attendance' => {} }) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'Guillermitos Bar', country: 'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:permissions) { [] }
  let(:event) { create(:late_event, campaign: campaign, company: company, place: place) }

  before do
    add_permissions permissions
    sign_in user
  end

  shared_examples_for 'a user that can create invites' do
    scenario 'can view the attendance module' do
      visit event_path(event)
      expect(page).to have_selector('h5', text: 'ATTENDANCE')
      expect(page).to have_button('New Activity')
    end

    scenario 'can create an invite' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('12 Invites')
      end
    end
  end

  shared_examples_for 'a user that can deactivate invites' do
    scenario 'can deactivate invites from the attendance table' do
      create(:invite, venue: event.venue, event: event)
      visit event_path(event)

      expect(page).to have_selector('#invites-list .resource-item')

      hover_and_click '#invites-list .resource-item', 'Deactivate Attendance Record'

      confirm_prompt 'Are you sure you want to deactivate this attendance record?'

      expect(page).to have_no_selector('#invites-list .resource-item')
    end
  end

  feature 'admin user' do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can create invites'
    it_behaves_like 'a user that can deactivate invites'
  end

  feature 'non admin user' do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can create invites' do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [[:index_invites, 'Event'], [:create_invite, 'Event'], [:show, 'Event']] }
    end

    it_should_behave_like 'a user that can deactivate invites' do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [[:index_invites, 'Event'], [:deactivate_invite, 'Event'], [:show, 'Event']] }
    end
  end

  def create_invite(account: nil, invites: 12)
    Sunspot.commit
    click_js_button 'New Activity'
    within visible_modal do
      select_from_chosen('Invitation', from: 'Activity type')
      select_from_autocomplete 'Search for a place', 'Guillermitos Bar'
      fill_in '# Invites', with: '12'
      click_js_button 'Create'
    end
    ensure_modal_was_closed
  end
end
