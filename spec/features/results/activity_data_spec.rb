require 'rails_helper'

feature 'Results Activity Data Page', js: true, search: true  do
  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:campaign) { create(:campaign, company: company) }
  let(:activity_type) { create(:activity_type, name: 'My Activity Type', company: company) }
  let(:venue) { create(:venue, place: create(:place, name: 'My Place'), company: company) }

  before { sign_in user }

  feature 'Activity Results', js: true, search: true do
    scenario 'GET index should display a table with the activities' do
      another_user = create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      another_at = create(:activity_type, name: 'Second Activity Type', company: company)
      campaign.activity_types << [activity_type, another_at]

      create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign,
                        company_user: company_user, activity_date: '2013-02-04')
      create(:activity, activity_type: another_at, activitable: venue, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-03-16')

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
      end
    end

    scenario 'allows to create apply and remove custom filters' do
      create(:campaign, name: 'First Campaign', company: company)
      create(:campaign, name: 'Second Campaign', company: company)
      create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'),
                            company: company)

      visit results_activities_path

      add_filter 'CAMPAIGNS', 'First Campaign'
      add_filter 'CAMPAIGNS', 'Second Campaign'
      add_filter 'USERS', 'Roberto Gomez'

      click_button 'Save'

      within visible_modal do
        fill_in('Filter name', with: 'My Custom Filter')
        expect do
          click_button 'Save'
          wait_for_ajax
        end.to change(CustomFilter, :count).by(1)
      end
      ensure_modal_was_closed

      expect(page).to have_filter_section('SAVED FILTERS')

      expect(collection_description).to have_filter_tag('First Campaign')
      expect(collection_description).to have_filter_tag('Second Campaign')
      expect(collection_description).to have_filter_tag('Roberto Gomez')

      click_js_button 'Reset'

      expect(collection_description).not_to have_filter_tag('First Campaign')
      expect(collection_description).not_to have_filter_tag('Second Campaign')
      expect(collection_description).not_to have_filter_tag('Roberto Gomez')

      add_filter 'SAVED FILTERS', 'My Custom Filter'

      expect(collection_description).to have_filter_tag('First Campaign')
      expect(collection_description).to have_filter_tag('Second Campaign')
      expect(collection_description).to have_filter_tag('Roberto Gomez')

      # Deselect filter
      filter_section('SAVED FILTERS').unicheck('My Custom Filter')

      expect(collection_description).not_to have_filter_tag('First Campaign')
      expect(collection_description).not_to have_filter_tag('Second Campaign')
      expect(collection_description).not_to have_filter_tag('Roberto Gomez')

      # Apply the saved filter
      add_filter 'SAVED FILTERS', 'My Custom Filter'

      expect(collection_description).to have_filter_tag('First Campaign')
      expect(collection_description).to have_filter_tag('Second Campaign')
      expect(collection_description).to have_filter_tag('Roberto Gomez')

      # Remove the custom filter
      click_js_link 'Filter Settings'

      within visible_modal do
        expect(page).to have_content('My Custom Filter')

        expect do
          click_js_link 'Remove Custom Filter'
          wait_for_ajax
        end.to change(CustomFilter, :count).by(-1)
        expect(page).to_not have_content('My Custom Filter')

        click_button 'Done'
      end
      ensure_modal_was_closed

      expect(page).not_to have_filter_section('SAVED FILTERS')
    end
  end

  feature 'export', search: true do
    before do
      another_user = create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
      activity_type2 = create(:activity_type, name: 'Second Activity Type', company: company)

      campaign.activity_types << activity_type
      campaign.activity_types << activity_type2
      # make sure activities are created before
      create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign,
                        company_user: company_user, activity_date: '2013-02-04')
      create(:activity, activity_type: activity_type2, activitable: venue, campaign: campaign,
                        company_user: another_user.company_users.first, activity_date: '2013-03-16')

      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit results_activities_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS',
         'CITY', 'STATE', 'ZIP'],
        [campaign.name, 'Test User', '2013-02-04T00:00', 'My Activity Type', nil, nil, 'My Place',
         'My Place, New York City, NY, 12345', 'New York City', 'NY', '12345'],
        [campaign.name, 'Juanito Bazooka', '2013-03-16T00:00', 'Second Activity Type', nil, nil,
         'My Place', 'My Place, New York City, NY, 12345', 'New York City', 'NY', '12345']
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
      end
    end
  end
end