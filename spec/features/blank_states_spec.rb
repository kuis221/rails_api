require 'rails_helper'

feature 'Blank States', search: true, js: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, modules: { 'attendance' => {} }) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'Guillermitos Bar', country: 'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:permissions) { [] }
  let(:event) { create(:late_event, campaign: campaign, place: place) }
  let(:venue) { create(:venue, company: company, place: place) }
  let(:role) { create(:non_admin_role, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  feature '/events', search: true  do
    feature 'with create permission' do
      let(:permissions) { [[:view_list, 'Event'], [:create, 'Event']] }

      scenario 'user see the proper message when no events are accessible' do
        visit events_path
        expect(page).to have_content('You do not have any events right now. Click the New Event button to schedule a new event.')
      end

      scenario 'user see the proper message when all events are filtered out' do
        company_user.campaigns << campaign
        company_user.places << place
        event
        Sunspot.commit
        visit events_path
        expect(page).to have_content('There are no events matching the filtering criteria you selected. Please select different filtering criteria.')
      end
    end

    feature 'without create permission' do
      let(:permissions) { [[:view_list, 'Event']] }

      scenario 'user see the proper message when no events are accessible' do
        visit events_path
        expect(page).to have_content('You do not have any events right now. No problem, as soon as events are added they will display in this section.')
      end
    end
  end
end
