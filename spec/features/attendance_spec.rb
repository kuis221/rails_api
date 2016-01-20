require 'rails_helper'

feature 'Attendance', js: true, search: true do
  let(:company) { create(:company) }
  let(:campaign) do
    create(:campaign,
           company: company, name: 'My Campaign',
           modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance',
                                        'settings' => { 'attendance_display' => '1' } } })
  end
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) do
    create(:place, name: 'Guillermitos Bar', country: 'CR', city: 'Curridabat',
                   state: 'San Jose', is_custom_place: true, reference: nil)
  end
  let(:area) { create(:area, name: 'California', company: company) }
  let(:permissions) { [] }
  let(:event) do
    create(:late_event, start_date: '11/01/2015', start_time: '04:30 pm',
                        campaign: campaign, place: place)
  end

  before do
    add_permissions permissions
    sign_in user
  end

  shared_examples_for 'a user that can create invites' do
    scenario 'user see a blank state message if no invites have been created' do
      visit event_path(event)
      expect(page).to have_selector('h5', text: 'ATTENDANCE')
      expect(page).to have_content('No Invites have been added to this event.')
      expect(page).to have_button('Add Invites')
    end

    scenario 'can create and edit an invite' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12

      change_attendance_display_by 'Venue'
      within '#invites-list tbody' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_no_content('No')
        expect(page).to have_content('12')
        expect(page).to have_content('0')
      end

      # Edit the invite
      hover_and_click resource_item(1, list: '#invites-list tbody'), 'Edit'

      within visible_modal do
        fill_in 'Invites', with: '20'
        fill_in 'RSVPs', with: '8'
        fill_in 'Attendees', with: '14'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within '#invites-list tbody' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('20 8 14')
      end

      # With KBMG setting enabled for the company
      company.update_attribute(:kbmg_enabled, 'true')
      event.venue.update_attribute(:top_venue, 'true')

      visit event_path(event)

      change_attendance_display_by 'Venue'
      within '#invites-list tbody' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('Yes No 20 8 14')
      end
    end

    scenario 'can create and edit an individual invite' do
      visit event_path(event)
      create_individual_invite account: 'Guillermitos Bar',
                               first_name: 'Enrique',
                               last_name: 'Bunbury',
                               email: 'bunbury@heroes.com'

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('Enrique Bunbury')
        expect(page).to have_content('bunbury@heroes.com')
        expect(page).to_not have_checked_field 'invite_individual[rsvpd]'
        expect(page).to_not have_checked_field 'invite_individual[attended]'
      end

      # Edit the invite
      hover_and_click resource_item(1, list: '#invites-list tbody'), 'Edit Invite'
      within visible_modal do
        unicheck "RSVP'd"
        unicheck 'Attended'
        fill_in 'Email', with: 'b@heroes.com'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('Enrique Bunbury')
        expect(page).to have_content('b@heroes.com')
        expect(page).to have_checked_field 'invite_individual[rsvpd]'
        expect(page).to have_checked_field 'invite_individual[attended]'
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

      hover_and_click resource_item(1, list: '#invites-list tbody'), 'Deactivate Invitation Record'

      confirm_prompt 'Are you sure you want to deactivate this invitation record?'

      expect(page).to have_no_selector('#invites-list tbody .resource-item')
    end

    scenario 'can deactivate individual invites from the attendance table' do
      invite = create :invite, venue: event.venue, event: event
      create :invite_individual, invite: invite, first_name: 'Leonardo', last_name: 'DiCaprio'
      visit event_path(event)

      within event_attendance_module do
        expect(page).to have_content 'Leonardo DiCaprio'
      end

      hover_and_click resource_item(1, list: '#invites-list tbody'), 'Deactivate Invitation Record'

      confirm_prompt 'Are you sure you want to deactivate this invitation record?'

      within event_attendance_module do
        expect(page).to have_content 'Leonardo DiCaprio'
      end
    end
  end

  shared_examples_for 'a user that can download invites' do
    scenario 'can export as csv with KBMG setting disabled for the company' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12
      change_attendance_display_by 'Venue'

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      wait_for_export_to_complete

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['Guillermitos Bar', '2015-11-01 16:30', 'My Campaign', '12', '0', '0']
      ])
    end

    scenario 'can export as csv with KBMG setting enabled for the company' do
      company.update_attribute(:kbmg_enabled, 'true')
      event.venue.update_attribute(:top_venue, 'true')

      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12
      change_attendance_display_by 'Venue'

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      wait_for_export_to_complete

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'TOP 100', 'JAMESON LOCALS', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['Guillermitos Bar', '2015-11-01 16:30', 'My Campaign', 'YES', 'NO', '12', '0', '0']
      ])
    end

    scenario 'can export individual as csv' do
      campaign.update_attributes(
        modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance',
                                     'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_individual_invite account: 'Guillermitos Bar',
                               first_name: 'Joaquin', last_name: 'Sabina',
                               email: 'jsabina@madrid.com'

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      wait_for_export_to_complete

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'NAME', 'EMAIL', "RSVP'd", 'ATTENDED'],
        ['Guillermitos Bar', '2015-11-01 16:30', 'My Campaign', 'Joaquin Sabina',
         'jsabina@madrid.com', 'NO', 'NO']
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

  def create_individual_invite(account: nil, first_name: 'Victor',
                               last_name: 'Manuel', email: 'victor@asturias.com')
    Sunspot.commit
    open_new_invite_modal
    within visible_modal do
      expect(page).to have_content 'New Invitation'
      fill_in 'First Name', with: first_name
      fill_in 'Last Name', with: last_name
      fill_in 'Email', with: email
      select_from_autocomplete 'Search for a venue...', account
      click_js_button 'Send Invitation'
    end
    ensure_modal_was_closed
  end

  def create_invite(account: nil, invites: 12)
    Sunspot.commit
    open_new_invite_modal
    within visible_modal do
      expect(page).to have_content 'New Invitation'
      click_js_link 'Venue Invitation'
      fill_in 'Invites', with: invites
      select_from_autocomplete 'Search for a venue...', account
      click_js_button "Send #{invites} Invitations"
    end
    ensure_modal_was_closed
  end

  def open_new_invite_modal
    if page.has_button?('Add Invites') # for the case of the blank state
      click_js_button 'Add Invites'
    else
      click_js_button 'Create Invites'
    end
  end
end
