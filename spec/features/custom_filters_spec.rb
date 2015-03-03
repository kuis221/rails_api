require 'rails_helper'

feature 'Custom filters', js: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San José', is_custom_place: true, reference: nil) }
  let(:permissions) { [] }
  let(:event) { create(:late_event, campaign: campaign, company: company, place: place) }
  let(:role) { create(:role, company: company) }

  before { sign_in user }

  scenario 'correctly applies the start end dates' do
    filter = create(:custom_filter,
           owner: company_user, name: 'FY2014', apply_to: 'events',
           filters:  'start_date=7%2F1%2F2013&end_date=6%2F30%2F2014')

    visit events_path
    expect(page).to have_filter_tag('Today To The Future')

    select_saved_filter 'FY2014'

    expect(collection_description).to have_filter_tag('Jul 01, 2013 - Jun 30, 2014')
    expect(page).to_not have_filter_tag('Today To The Future')
  end
end