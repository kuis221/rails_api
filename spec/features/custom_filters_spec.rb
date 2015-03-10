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
    create(:custom_filter,
           owner: company_user, name: 'FY2014', apply_to: 'events',
           filters: 'start_date=7%2F1%2F2013&end_date=6%2F30%2F2014')

    visit events_path

    expect(page).to have_filter_tag('Today To The Future')

    select_saved_filter 'FY2014'
    expand_filter('FY2014')
    expect(collection_description).to have_filter_tag('Jul 01, 2013 - Jun 30, 2014')
    expect(page).to_not have_filter_tag('Today To The Future')
  end

  scenario 'remove checked for custom filters checkboxes when filter is removed' do
    custom_filter_category = create(:custom_filters_category, name: 'Divisions', company: company)
    area1 = create(:area, name: 'Some Area', description: 'an area description', company: company)
    area2 = create(:area, name: 'Another Area', description: 'another area description', company: company)

    create(:custom_filter,
           owner: company_user, name: 'Continental', apply_to: 'events',
           filters: "area%5B%5D=#{area1.id}&area%5B%5D=#{area2.id}",
           category: custom_filter_category)

    visit events_path

    filter_section('DIVISIONS').unicheck('Continental')

    expect(collection_description).to have_filter_tag('Continental')

    expand_filter('Continental')
    expect(page).to have_filter_tag('Some Area')
    expect(page).to have_filter_tag('Another Area')

    remove_filter('Another Area')

    within '.form-facet-filters' do
      expect(find_field('Continental')).not_to be_checked
    end
    expect(page).to have_filter_tag('Some Area')
    expect(page).not_to have_filter_tag('Another Area')
  end

  scenario 'remove checked for dates custom filters checkboxes when custom dates are selected from calendar' do
    custom_filter_category = create(:custom_filters_category, name: 'Fiscal Years', company: company)

    create(:custom_filter,
           owner: company_user, name: 'FY2014', apply_to: 'events',
           filters: 'start_date=7%2F1%2F2013&end_date=6%2F30%2F2014',
           category: custom_filter_category)

    visit events_path

    filter_section('FISCAL YEARS').unicheck('FY2014')

    within '.form-facet-filters' do
      expect(page).not_to have_content('FY2014')
    end
    expand_filter('FY2014')
    expect(collection_description).to have_filter_tag('Jul 01, 2013 - Jun 30, 2014')

    select_filter_calendar_day('18', '19')

    within '.form-facet-filters' do
      expect(find_field('FY2014')).not_to be_checked
    end
    expect(collection_description).to have_filter_tag('Jul 18, 2013 - Jul 19, 2013')
  end
end
