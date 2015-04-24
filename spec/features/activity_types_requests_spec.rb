require 'rails_helper'

feature 'Activity Types', js: true do
  before do
    Warden.test_mode!
    @user = create(:user, company_id: create(:company).id, role_id: create(:role).id)
    @company = @user.companies.first
    sign_in @user
    allow_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  feature 'List view', search: true  do
    scenario 'GET index should display a table with the day_parts' do
      activity_types = [
        create(:activity_type, company: @company, name: 'Mornings',
               description: 'From 8 to 11am', active: true),
        create(:activity_type, company: @company, name: 'Afternoons',
               description: 'From 1 to 6pm', active: true)
      ]
      Sunspot.commit
      visit activity_types_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content('Afternoons')
        expect(page).to have_content('From 1 to 6pm')
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('Mornings')
        expect(page).to have_content('From 8 to 11am')
      end
    end

    scenario 'allows the user to create a new activity type' do
      visit activity_types_path

      click_js_button 'New Activity Type'

      within visible_modal do
        fill_in 'Name', with: 'Activity Type name'
        fill_in 'Description', with: 'activity type description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'Activity Type name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'Activity Type name')
      expect(page).to have_selector('div.description-data', text: 'activity type description')
    end

    scenario 'should allow user to deactivate activity types' do
      create(:activity_type, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: @company)
      Sunspot.commit
      visit activity_types_path

      expect(page).to have_content('A Vinos ticos')
      within resource_item 1 do
        click_js_button 'Deactivate Activity Type'
      end
      confirm_prompt 'Are you sure you want to deactivate this activity type?'

      expect(page).to have_no_content('A Vinos ticos')
    end

    scenario 'should allow user to activate activity type' do
      create(:activity_type, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica',
             active: false, company: @company)
      Sunspot.commit
      visit activity_types_path

      # Make it show only the inactive elements
      add_filter 'ACTIVE STATE', 'Inactive'
      remove_filter 'Active'

      expect(page).to have_content '1 activity type found for: Inactive'

      expect(page).to have_content('A Vinos ticos')
      within resource_item 1 do
        click_js_button 'Activate Activity Type'
      end
      expect(page).to have_no_content('A Vinos ticos')
    end

    scenario 'should allow user to edit an activity type' do
      create(:activity_type, name: 'A test activity type', description: 'Algunos vinos de Costa Rica', company: @company)
      Sunspot.commit
      visit activity_types_path

      expect(page).to have_content('A test activity type')
      within resource_item 1 do
        click_js_button 'Edit Activity Type'
      end

      within visible_modal do
        fill_in 'Name', with: 'Drink feature'
        fill_in 'Description', with: 'A description for drink feature type'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within resource_item 1 do
        expect(page).to have_no_content('A test activity type')
        expect(page).to have_content('Drink feature')
        expect(page).to have_content('A description for drink feature type')
      end
    end

    it_behaves_like 'a list that allow saving custom filters' do
      let(:list_url) { activity_types_path }

      let(:filters) { [{ section: 'ACTIVE STATE', item: 'Inactive' }] }
    end
  end

  feature 'Details view' do
    scenario 'should allow user to edit an activity type' do
      activity_type = create(:activity_type, name: 'A test activity type',
                             description: 'Algunos vinos de Costa Rica',
                             company: @company)
      Sunspot.commit
      visit activity_type_path(activity_type)

      expect(page).to have_selector('h2', text: 'A test activity type')
      find('.edition-links').click_js_button('Edit Activity Type')

      within visible_modal do
        fill_in 'Name', with: 'Drink feature'
        fill_in 'Description', with: 'A description for drink feature type'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Drink feature')
      expect(page).to have_selector('div.description-data', text: 'A description for drink feature type')
    end
  end

  feature 'export', search: true do
    let(:activity_type1) { create(:activity_type, company: @company, name: 'Activity Type 1',
                                  description: 'First description', active: true) }
    let(:activity_type2) { create(:activity_type, company: @company, name: 'Activity Type 2',
                                  description: 'Second description', active: true) }

    before do
      # make sure activity types are created before
      activity_type1
      activity_type2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit activity_types_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['Activity Type 1', 'First description', 'Active'],
        ['Activity Type 2', 'Second description', 'Active']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit activity_types_path

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
        expect(text).to include 'ActivityTypes'
        expect(text).to include 'ActivityType1'
        expect(text).to include 'Firstdescription'
        expect(text).to include 'ActivityType2'
        expect(text).to include 'Seconddescription'
      end
    end
  end
end
