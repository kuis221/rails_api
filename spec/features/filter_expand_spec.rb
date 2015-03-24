require 'rails_helper'

feature 'Filter Expand', js: true, search: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature 'filter expand' do
    let(:team) { create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true, company_id: company.id) }
    let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
    let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: company) }
    let(:events) do
      [
        create(:event,
               start_date: '08/21/2013', end_date: '08/21/2013', company: company),
        create(:event,
               start_date: '08/28/2013', end_date: '08/29/2013', company: company)
      ]
    end

    scenario 'Allows expanding the filter team' do
      team.users << [user1, user2]
      events[0].users << user1
      events[1].users << user2
      Sunspot.commit

      visit events_path
      remove_filter 'Today To The Future'

      expect(page).to have_selector('#events-list .resource-item', count: 2)
      expect(page).to have_filter_section('PEOPLE',
                                          options: ['Costa Rica Team', 'Mario Moreno', 'Roberto Gomez', 'Test User'])

      filter_section('PEOPLE').unicheck('Costa Rica Team')

      expect(collection_description).to have_filter_tag('Costa Rica Team')
      expand_filter 'Costa Rica Team'

      expect(collection_description).to_not have_filter_tag('Costa Rica Team')
      expect(collection_description).to have_filter_tag('Mario Moreno')
      expect(collection_description).to have_filter_tag('Roberto Gomez')

      remove_filter 'Roberto Gomez'
      expect(page).to have_selector('#events-list .resource-item', count: 1)
    end

    scenario 'Allows expanding the saved filters' do
      campaign2 = create(:campaign, name: 'Imperial FYU', company: company)
      create_list(:event, 3, company: company, campaign: campaign2)
      events
      Sunspot.commit

      visit events_path
      remove_filter 'Today To The Future'

      expect(page).to have_selector('#events-list .resource-item', count: 5)

      filter_section('CAMPAIGN').unicheck('Imperial FYU')

      expect(page).to have_selector('#events-list .resource-item', count: 3)
      create(:custom_filter,
              owner: company_user, name: 'My Custom Filter', apply_to: 'events',
              filters:  "status%5B%5D=Active&campaign%5B%5D=#{campaign2.id}")

      visit events_path
      remove_filter 'Today To The Future'
      expect(page).to have_selector('#events-list .resource-item', count: 5)

      filter_section('SAVED FILTERS').unicheck('My Custom Filter')
      expect(page).to have_selector('#events-list .resource-item', count: 3)
      expect(collection_description).to have_filter_tag('My Custom Filter')

      expand_filter 'My Custom Filter'
      expect(collection_description).to_not have_filter_tag('My Custom Filter')
      expect(collection_description).to have_filter_tag('Imperial FYU')

      remove_filter 'Imperial FYU'
      expect(page).to have_selector('#events-list .resource-item', count: 5)
    end

    scenario 'Allows expanding the saved filters - Date Range' do
      campaign2 = create(:campaign, name: 'Imperial FYU', company: company)
      create_list(:event, 3, company: company, campaign: campaign2)
      events
      Sunspot.commit

      visit events_path
      remove_filter 'Today To The Future'

      expect(page).to have_selector('#events-list .resource-item', count: 5)

      create(:custom_filter,
              owner: company_user, name: 'My Custom Filter', apply_to: 'events',
              filters:  "status%5B%5D=Active&start_date=8%2F28%2F2013&end_date=8%2F29%2F2013")

      visit events_path
      remove_filter 'Today To The Future'
      filter_section('SAVED FILTERS').unicheck('My Custom Filter')
      expect(page).to have_selector('#events-list .resource-item', count: 1)

      expect(collection_description).to have_filter_tag('My Custom Filter')

      expand_filter 'My Custom Filter'
      expect(collection_description).to_not have_filter_tag('My Custom Filter')
      expect(collection_description).to have_filter_tag('Aug 28, 2013 - Aug 29, 2013')

      expect(page).to have_selector('#events-list .resource-item', count: 1)
    end

    scenario 'Expanding custom filters should not clear previously selected filters' do
      today = Time.zone.local(Time.now.year, Time.now.month, Time.now.day, 12, 00)
      custom_filter_category = create(:custom_filters_category, name: 'Divisions', company: company)
      area1 = create(:area, name: 'Some Area', description: 'an area description', company: company)
      area2 = create(:area, name: 'Another Area', description: 'another area description', company: company)

      create(:custom_filter,
             owner: company_user, name: 'Continental', apply_to: 'events',
             filters: "area%5B%5D=#{area1.id}&area%5B%5D=#{area2.id}",
             category: custom_filter_category)

      create_list(:event, 2,
                  start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                  company: company, campaign: campaign)
      events
      Sunspot.commit

      visit events_path

      remove_filter 'Today To The Future'
      choose_predefined_date_range 'Today'
      wait_for_ajax

      expect(page).to have_selector('#events-list .resource-item', count: 2)

      filter_section('DIVISIONS').unicheck('Continental')

      expect(collection_description).to have_filter_tag('Continental')

      expand_filter('Continental')
      expect(page).to have_filter_tag('Some Area')
      expect(page).to have_filter_tag('Another Area')
      expect(page).to have_filter_tag('Today')

      expect(page).to have_selector('#events-list .resource-item', count: 0)

      within('.select-ranges') do
        expect(page).to have_no_content('Choose a date range')
      end
    end
  end
end