require 'rails_helper'

feature 'Results Activity Data Page', js: true, search: true  do
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:campaign) { create(:campaign, company: company) }
  let(:activity_type) { create(:activity_type, name: 'My Activity Type', company: company) }
  let(:inactive_event) { create(:submitted_event, company: company, campaign: campaign, place: create(:place, name: 'The Place'), active: false) }
  let(:venue) { create(:venue, place: create(:place, name: 'My Place'), company: company) }

  before { sign_in user }

  feature 'Activity Results', js: true, search: true do
    scenario 'GET index should display a table with the activities' do
      event = create(:approved_event, company: company, campaign: campaign, place: create(:place, name: 'Another Place'))
      another_user = create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      another_at = create(:activity_type, name: 'Second Activity Type', company: company)
      campaign.activity_types << [activity_type, another_at]

      create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign,
                        company_user: company_user, activity_date: '2013-02-04')
      create(:activity, activity_type: another_at, activitable: venue, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-03-16')
      create(:activity, activity_type: activity_type, activitable: event, campaign: campaign,
                        company_user: company_user, activity_date: '2013-03-25')
      create(:activity, activity_type: activity_type, activitable: inactive_event, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-03-28')

      campaign.activity_types << activity_type
      campaign.activity_types << another_at
      Sunspot.commit

      visit results_activities_path

      within('#activities-list') do
        # First Row
        within resource_item 1 do
          expect(page).to have_content('My Activity Type')
          expect(page).to have_content('MON Feb 4, 2013')
          expect(page).to have_content('Test User')
        end

        # Second Row
        within resource_item 2 do
          expect(page).to have_content('Second Activity Type')
          expect(page).to have_content('SAT Mar 16, 2013')
          expect(page).to have_content('Juanito Bazooka')
        end

        # Third Row
        within resource_item 3 do
          expect(page).to have_content('My Activity Type')
          expect(page).to have_content('MON Mar 25, 2013')
          expect(page).to have_content('Test User')
        end

        # Activities from inactive events should not be displayed
        expect(page).to_not have_content('THU Mar 28, 2013')
      end
    end

    it_behaves_like 'a list that allow saving custom filters' do
      before do
        create(:campaign, name: 'First Campaign', company: company)
        create(:campaign, name: 'Second Campaign', company: company)
        create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'),
                              company: company)
      end

      let(:list_url) { results_activities_path }

      let(:filters) do
        [{ section: 'CAMPAIGNS', item: 'First Campaign' },
         { section: 'CAMPAIGNS', item: 'Second Campaign' },
         { section: 'USERS', item: 'Roberto Gomez' }]
      end
    end
  end

  feature 'export', search: true do
    before do
      event = create(:event, campaign: campaign, place: venue.place)
      another_user = create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      activity_type2 = create(:activity_type, name: 'Second Activity Type', company: company)
      place1 = create(:place, name: 'Custom Name 1', formatted_address: 'Custom Place 1, Curridabat')
      place2 = create(:place, name: 'Custom Name 2', formatted_address: nil)
      place_field1 = create(:form_field, name: 'Custom Place 1', type: 'FormField::Place', fieldable: activity_type, ordering: 1)
      place_field2 = create(:form_field, name: 'Custom Place 2', type: 'FormField::Place', fieldable: activity_type, ordering: 2)

      campaign.activity_types << activity_type
      campaign.activity_types << activity_type2
      # make sure activities are created before
      activity = create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign,
                                   company_user: company_user, activity_date: '2013-02-04',
                                   created_at: DateTime.parse('2015-07-01 02:11 -07:00'),
                                   updated_at: DateTime.parse('2015-07-03 02:11 -07:00'))
      create(:activity, activity_type: activity_type2, activitable: venue, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-03-16',
                        created_at: DateTime.parse('2015-07-01 02:11 -07:00'),
                        updated_at: DateTime.parse('2015-07-03 02:11 -07:00'))
      create(:activity, activity_type: activity_type, activitable: event, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-09-04',
                        created_at: DateTime.parse('2015-07-01 02:11 -07:00'),
                        updated_at: DateTime.parse('2015-07-03 02:11 -07:00'))
      create(:activity, activity_type: activity_type, activitable: inactive_event, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-03-28',
                        created_at: DateTime.parse('2015-07-01 02:11 -07:00'),
                        updated_at: DateTime.parse('2015-07-03 02:11 -07:00'))

      activity.results_for([place_field1]).first.value = place1.id
      activity.results_for([place_field2]).first.value = place2.id
      activity.save

      Sunspot.commit
    end

    scenario 'should be able to export as CSV' do
      visit results_activities_path

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS',
         'CITY', 'STATE', 'ZIP', 'COUNTRY', 'ACTIVE STATE', 'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY',
         'CUSTOM PLACE 1', 'CUSTOM PLACE 2'],
        [campaign.name, 'Test User', '2013-02-04', 'My Activity Type', '', nil, 'My Place',
         'My Place, 11 Main St., New York City, NY, 12345', 'New York City', 'NY', '12345', 'US', 'Active',
         '2015-07-01 02:11', 'Test User', '2015-07-03 02:11', 'Test User', 'Custom Name 1, Custom Place 1, Curridabat', 'Custom Name 2'],
        [campaign.name, 'Juanito Bazooka', '2013-03-16', 'Second Activity Type', '', nil,
         'My Place', 'My Place, 11 Main St., New York City, NY, 12345', 'New York City', 'NY', '12345', 'US', 'Active',
         '2015-07-01 02:11', 'Test User', '2015-07-03 02:11', 'Test User', nil, nil],
        [campaign.name, 'Juanito Bazooka', '2013-09-04', 'My Activity Type', '', nil,
         'My Place', 'My Place, 11 Main St., New York City, NY, 12345', 'New York City', 'NY', '12345', 'US', 'Active',
         '2015-07-01 02:11', 'Test User', '2015-07-03 02:11', 'Test User', nil, nil]
      ])

      expect(ListExport.last).to_not have_rows([
        [campaign.name, 'Juanito Bazooka', '2013-03-28', 'My Activity Type', '', nil, 'The Place',
         'The Place, 11 Main St., New York City, NY, 12345', 'New York City', 'NY', '12345', 'US', 'Active',
         '2015-07-01 02:11', 'Test User', '2015-07-03 02:11', 'Test User', nil, nil]
      ])
    end

    scenario 'should be able to export as PDF' do
      visit results_activities_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      export = ListExport.last
      # Test the generated PDF...
      reader = PDF::Reader.new(open(export.file.url))
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include 'MyActivityType'
        expect(text).to include 'MONFeb4,2013'
        expect(text).to include 'TestUser'
        expect(text).to include 'SecondActivityType'
        expect(text).to include 'SATMar16,2013'
        expect(text).to include 'JuanitoBazooka'
        expect(text).to include 'WEDSep4,2013'
        expect(text).to_not include 'THUMar28,2013'
      end
    end
  end
end