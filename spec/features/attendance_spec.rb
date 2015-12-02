require 'rails_helper'

feature 'Attendance', js: true, search: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '1' } } }) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'Guillermitos Bar', country: 'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:area) { create(:area, name: 'California', company: company) }
  let(:permissions) { [] }
  let(:event) { create(:late_event, campaign: campaign, company: company, place: place) }

  before do
    add_permissions permissions
    sign_in user
  end

  shared_examples_for 'a user that can create invites' do
    scenario 'user sees a blank state message if no invites have been created' do
      visit event_path(event)
      expect(page).to have_selector('h5', text: 'ATTENDANCE')
      expect(page).to have_content('No Invites have been added to this event.')
      expect(page).to have_button('Add Invites')
    end

    scenario 'can view the attendance module if invites were created' do
      invite = create(:invite, event: event, venue: event.venue)
      create :invite_individual, invite: invite
      visit event_path(event)
      expect(page).to have_selector('h5', text: 'ATTENDANCE')
      within event_attendance_module do
        expect(page).to have_content event.venue.name
      end
      expect(page).to have_button('Add Activity')
    end

    scenario 'can create and edit an invite when attendance display is set as Venue' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('No Jameson Locals')
        expect(page).to have_content('No Top 100')
        expect(page).to have_content('12 Invites')
        expect(page).to have_content('0 RSVPs')
        expect(page).to have_content('0 Attendees')
      end

      # Edit the invite
      hover_and_click resource_item(1, list: '#invites-list'), 'Edit'

      within visible_modal do
        fill_in '# Invites', with: '20'
        fill_in '# RSVPs', with: '8'
        fill_in '# Attendes', with: '14'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('No Jameson Locals')
        expect(page).to have_content('No Top 100')
        expect(page).to have_content('20 Invites')
        expect(page).to have_content('8 RSVPs')
        expect(page).to have_content('14 Attendees')
      end
    end

    scenario 'can create and edit an invite when attendance display is set as Market' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_invite account: 'California', invites: 10, type: 'market'

      within '#invites-list' do
        expect(page).to have_content('California')
        expect(page).to_not have_content('No Jameson Locals')
        expect(page).to_not have_content('No Top 100')
        expect(page).to have_content('10 Invites')
        expect(page).to have_content('0 RSVPs')
        expect(page).to have_content('0 Attendees')
      end

      # Edit the invite
      hover_and_click resource_item(1, list: '#invites-list'), 'Edit Invite'
      within visible_modal do
        fill_in '# Invites', with: '15'
        fill_in '# RSVPs', with: '6'
        fill_in '# Attendes', with: '9'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within '#invites-list' do
        expect(page).to have_content('California')
        expect(page).to_not have_content('No Jameson Locals')
        expect(page).to_not have_content('No Top 100')
        expect(page).to have_content('15 Invites')
        expect(page).to have_content('6 RSVPs')
        expect(page).to have_content('9 Attendees')
      end
    end
  end

  shared_examples_for 'a user that can deactivate invites' do
    scenario 'can deactivate invites from the attendance table' do
      create(:invite, venue: event.venue, event: event)
      visit event_path(event)

      within event_attendance_module do
        expect(page).to_not have_selector('#invites-list .resource-item')
        click_js_link 'by Venue'
        expect(page).to have_selector('#invites-list .resource-item')
      end

      hover_and_click resource_item(1, list: '#invites-list'), 'Deactivate Invitation Record'

      confirm_prompt 'Are you sure you want to deactivate this invitation record?'

      expect(page).to have_no_selector('#invites-list .resource-item')
    end

    scenario 'can deactivate individual invites from the attendance table' do
      invite = create :invite, venue: event.venue, event: event
      create :invite_individual, invite: invite, first_name: 'Leonardo', last_name: 'DiCaprio'
      visit event_path(event)

      within event_attendance_module do
        expect(page).to have_content 'Leonardo DiCaprio'
      end

      hover_and_click resource_item(1, list: '#invites-list'), 'Deactivate Invitation Record'

      confirm_prompt 'Are you sure you want to deactivate this invitation record?'

      within event_attendance_module do
        expect(page).to have_content 'Leonardo DiCaprio'
      end
    end
  end

  shared_examples_for 'a user that can download invites' do
    scenario 'can export as csv' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12
      change_attendance_display_by 'Venue'

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      wait_for_export_to_complete

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['VENUEEVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['Guillermitos Bar', '2015-11-11 10:00', 'Campaign 1', '12', '0', '0']
      ])
    end

    scenario 'can export individual as csv' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_invite account: 'California', invites: 12

      click_js_link 'Download'
      click_js_link 'Download individual to CSV'

      wait_for_export_to_complete

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['MARKET', 'REGISTRANT ID', 'DATE ADDED', 'EMAIL', 'MOBILE PHONE', 'MOBILE SIGN UP',
         'FIRST NAME', 'LAST NAME', 'ATTENDED PREVIOUS BARTENDER BALL', 'OPT IN TO FUTURE COMMUNICATION',
         'PRIMARY REGISTRANT ID', 'BARTENDER HOW LONG', 'BARTENDER ROLE', 'DATE OF BIRTH', 'ZIP CODE']
      ])
    end

    scenario 'can export aggregate as csv' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_invite account: 'California', invites: 12

      click_js_link 'Download'
      click_js_link 'Download aggregate to CSV'

      wait_for_export_to_complete

      expect(ListExport.last).to have_rows([
        %w(MARKET INVITES RSVPs ATTENDEES),
        %w(California 12 0 0)
      ])
    end
  end

  feature 'non admin user' do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can create invites' do
      before { area.places << place }
      before { campaign.areas << area }
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      before { company_user.areas << area }
      let(:permissions) { [[:index_invites, 'Event'], [:create_invite, 'Event'], [:edit_invite, 'Event'], [:show, 'Event']] }
    end

    it_should_behave_like 'a user that can deactivate invites' do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [[:index_invites, 'Event'], [:deactivate_invite, 'Event'], [:show, 'Event']] }
    end

    it_should_behave_like 'a user that can download invites' do
      before { area.places << place }
      before { campaign.areas << area }
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      before { company_user.areas << area }
      let(:permissions) { [[:index_invites, 'Event'], [:create_invite, 'Event'], [:show, 'Event']] }
    end
  end


  def event_attendance_module
    find '#event-attendance'
  end

  def change_attendance_display_by(mode)
      within event_attendance_module do
        click_js_link "by #{mode}"
        expect(page).to have_selector 'a.active', text: "by #{mode}"
      end
  end

  def create_invite(account: nil, invites: 12)
    Sunspot.commit
    if page.has_button?('Add Invites')  # for the case of the blank state
      click_js_button 'Add Invites'
    else
      click_js_button 'Create Invites'
    end
    within visible_modal do
      expect(page).to have_content 'New Invitation'
      click_js_link 'Venue Invitation'
      fill_in '# Invites', with: invites
      select_from_autocomplete 'Search for a place', account
      click_js_button 'Create'
    end
    ensure_modal_was_closed
  end
end
