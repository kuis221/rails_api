require 'rails_helper'

feature 'Filter Settings', search: true, js: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature 'filter settings' do
    let(:campaign1) { create(:campaign, name: 'Campaign 1', company: company) }
    let(:campaign2) { create(:campaign, name: 'Campaign 2', company: company, aasm_state: 'inactive') }
    let(:brand1) { create(:brand, name: 'Brand 1', company: company) }
    let(:brand2) { create(:brand, name: 'Brand 2', company: company, active: false) }
    let(:event1) { create(:submitted_event, campaign: campaign1) }
    let(:event2) { create(:late_event, campaign: campaign2) }
    let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
    let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: company) }
    let(:user3) { create(:company_user, user: create(:user, first_name: 'Eugenio', last_name: 'Derbez'), company: company, active: false) }

    scenario 'allows to configure filter settings' do
      event1.users << user1
      event1.users << user2
      event1.users << user3
      event2.users << user2
      campaign1.brands << brand1
      campaign1.brands << brand2
      campaign2.brands << brand2
      Sunspot.commit

      visit events_path

      expect(page).to have_filter_section('CAMPAIGNS', options: ['Campaign 1'])

      expect(page).to have_filter_section('BRANDS', options: ['Brand 1'])
      expect(page).to have_filter_section('PEOPLE',
                                          options: ['Mario Moreno', 'Roberto Gomez', 'Test User'])

      click_js_link 'Filter Settings'

      within visible_modal do
        unicheck('Show inactive items')
        click_button 'Done'
      end
      ensure_modal_was_closed

      # checks that the filter sections were hidden
      expect(page).to have_filter_section('CAMPAIGNS', options: ['Campaign 1', 'Campaign 2'])
      expect(page).to have_filter_section('BRANDS', options: ['Brand 1', 'Brand 2'])
      expect(page).to have_filter_section('PEOPLE',
                                          options: ['Eugenio Derbez', 'Mario Moreno', 'Roberto Gomez', 'Test User'])
      expect(page).to have_filter_section('EVENT STATUS')
      expect(page).to have_filter_section('ACTIVE STATE')

      click_js_link 'Filter Settings'

      within visible_modal do
        unicheck('Show inactive items')
        click_button 'Done'
      end
      ensure_modal_was_closed

      expect(page).to have_filter_section('CAMPAIGNS', options: ['Campaign 1'])
      expect(page).to have_filter_section('BRANDS', options: ['Brand 1'])
      expect(page).to have_filter_section('PEOPLE',
                                          options: ['Mario Moreno', 'Roberto Gomez', 'Test User'])
      expect(page).to have_filter_section('EVENT STATUS')
      expect(page).to have_filter_section('ACTIVE STATE')
      screenshot_and_open_image
    end
  end
end
