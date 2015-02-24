require 'rails_helper'

feature 'As a Super Admin, I want to login as another system user' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { create(:event, campaign: campaign, company: company) }

  before do
    Warden.test_mode!
    sign_in user
  end
  after do
    Warden.test_reset!
  end

  feature 'admin user', js: true  do
    let(:role) { create(:role, company: company) }
    let(:events)do
      [
        create(:event,
               start_date: '08/21/2013', end_date: '08/21/2013',
               start_time: '10:00am', end_time: '11:00am',
               campaign: campaign, active: true,
               place: create(:place, name: 'Campaign #1 FY2012')),
        create(:event,
               start_date: '08/28/2013', end_date: '08/29/2013',
               start_time: '11:00am', end_time: '12:00pm',
               campaign: create(:campaign, name: 'Campaign #2 FY2012', company: company),
               place: create(:place, name: 'Place 2'), company: company)
      ]
    end

    scenario 'a user that view custom user navigation' do
      
      events[0].users << create(:company_user,
                      user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company)
      events[1].users << create(:company_user,
                      user: create(:user, first_name: 'Mario', last_name: 'Cantinflas'), company: company)
      events  # make sure events are created before
      Sunspot.commit
      
      visit events_path

      expect(page).to have_selector('.top-admin-login-navigation', count: 1)
      click_link 'Login as as specific user'

      expect(page).to have_selector('#select_custom_user_chzn', count: 1)
      select_from_chosen 'Roberto Gomez', from: 'Choose a user that you want to login as'

      click_link 'Login'

      expect(page).to have_content('You are logged in as Roberto Gomez')
    end
  end

  feature 'non admin user', js: true  do
    let(:role) { create(:non_admin_role, company: company) }

    scenario 'a user that not view custom user navigation' do
      visit events_path
      expect(page).to_not have_selector('.top-admin-login-navigation')
    end
  end
end