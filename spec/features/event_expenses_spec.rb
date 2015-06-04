require 'rails_helper'

feature 'Event Expenses', js: true, search: true do
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
    company_user.campaigns << campaign
    company_user.places << place
    sign_in user
  end

  feature 'a user with permissions to create expenses' do
    let(:permissions) { [[:show, 'Event'], [:index_expenses, 'Event'], [:create_expense, 'Event']] }
    scenario '' do
    end
  end
end
