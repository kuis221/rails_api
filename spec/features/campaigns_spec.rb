require 'rails_helper'

feature 'Campaigns', js: true do

  let(:role) { create(:role, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company) { create(:company) }
  let(:company_user) { user.company_users.first }
  let(:campaign) { create(:campaign, company: company) }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can add staff to campaigns' do
    scenario 'can successfuly add a user to a campaign' do
      Kpi.create_global_kpis
      create(:company_user, company: company, role: company_user.role,
                            user: create(:user, first_name: 'Alberto',
                                                last_name: 'Porras'))
      visit campaign_path(campaign)
      staff_tab = open_tab('Staff')
      click_js_button 'Add Staff'
      within visible_modal do
        within resource_item do
          expect(page).to have_content('Alberto Porras')
          click_js_link 'Add'
        end
        expect(page).not_to have_content('Alberto Porras')
      end
      close_modal

      within staff_tab do
        expect(page).to have_content('Alberto Porras')
      end
    end
  end

  feature 'Index', search: true  do
    scenario 'should display a table with the campaigns' do
      campaigns = [
        create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: company),
        create(:campaign, name: 'Centenario FY12', description: 'ron Centenario test campaign', company: company)
      ]
      Sunspot.commit
      visit campaigns_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content(campaigns[0].name)
        expect(page).to have_content(campaigns[0].description)
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content(campaigns[1].name)
        expect(page).to have_content(campaigns[1].description)
      end
    end

    scenario 'should allow user to deactivate campaigns' do
      create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: company)
      Sunspot.commit
      visit campaigns_path

      expect(page).to have_content('Cacique FY13')
      within resource_item 1 do
        click_js_button('Deactivate Campaign')
      end

      confirm_prompt 'Are you sure you want to deactivate this campaign?'

      expect(page).to have_no_content('Cacique FY13')
    end

    scenario 'should allow user to activate campaigns' do
      create(:inactive_campaign, name: 'Cacique FY13',
        description: 'test campaign for guaro cacique', company: company)
      Sunspot.commit
      visit campaigns_path

      # Make it show only the inactive elements
      add_filter 'ACTIVE STATE', 'Inactive'
      remove_filter 'Active'

      expect(page).to have_content '1 campaign found for: Inactive'

      expect(page).to have_content('Cacique FY13')
      within resource_item 1 do
        expect(page).to have_content('Cacique FY13')
        click_js_button('Activate Campaign')
      end
      expect(page).to have_no_content('Cacique FY13')
    end

    scenario 'allows the user to create a new campaign' do
      create(:brand_portfolio, name: 'Test portfolio', company: company)
      visit campaigns_path

      click_js_button 'New Campaign'

      within('form#new_campaign') do
        fill_in 'Name', with: 'new campaign name'
        fill_in 'Description', with: 'new campaign description'
        fill_in 'Start date', with: '01/22/2013'
        fill_in 'End date', with: '01/22/2014'
        select_from_chosen('Test portfolio', from: 'Brand portfolios', match: :first)
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new campaign name') # Wait for the page to load
      campaign = Campaign.last
      expect(page).to have_selector('h2', text: 'new campaign name')
      expect(page).to have_selector('div.description-data', text: 'new campaign description')
      expect(campaign.start_date).to eql Date.parse('2013-01-22')
      expect(campaign.end_date).to eql Date.parse('2014-01-22')
    end
  end

  feature 'Details page', js: true do
    scenario 'GET show should display the campaign details page' do
      campaign = create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: company)
      visit campaign_path(campaign)
      expect(page).to have_selector('h2', text: 'Some Campaign')
      expect(page).to have_selector('div.description-data', text: 'a campaign description')
    end

    scenario 'allows the user to activate/deactivate a campaign' do
      campaign = create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: company)
      visit campaign_path(campaign)
      within('.edition-links') do
        click_js_button('Deactivate Campaign')
      end

      confirm_prompt 'Are you sure you want to deactivate this campaign?'

      within('.edition-links') do
        click_js_button('Activate Campaign')
        expect(page).to have_button('Deactivate Campaign') # test the link have changed
      end
    end

    scenario 'allows the user to edit the campaign' do
      visit campaign_path(campaign)

      within('.edition-links') { click_js_button 'Edit Campaign' }

      within("form#edit_campaign_#{campaign.id}") do
        fill_in 'Name', with: 'edited campaign name'
        fill_in 'Description', with: 'edited campaign description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      # find('h2', text: 'edited campaign name') # Wait for the page to reload
      expect(page).to have_selector('h2', text: 'edited campaign name')
      expect(page).to have_selector('div.description-data', text: 'edited campaign description')
    end

    scenario 'should be able to assign areas to the campaign' do
      Kpi.create_global_kpis
      area = create(:area, name: 'San Francisco Area', company: company)
      area2 = create(:area, name: 'Los Angeles Area', company: company)
      visit campaign_path(campaign)

      tab = open_tab('Places')

      click_js_button 'Add Places'

      within visible_modal do
        fill_in 'place-search-box', with: 'San'
        expect(page).to have_content('San Francisco Area')
        expect(page).to have_no_content('Los Angeles Area')
        within(resource_item(area)) { click_js_link('Add Area') }
        expect(page).to have_no_selector("#area-#{area.id}") # The area was removed from the available areas list
      end
      close_modal

      # Re-open the modal to make sure it's not added again to the list
      click_js_button 'Add Places'

      within visible_modal do
        expect(page).to have_no_selector("#area-#{area.id}") # The area does not longer appear on the list after it was added to the campaign
        expect(page).to have_selector("#area-#{area2.id}")
      end
      close_modal

      within tab do
        # Ensure the area now appears on the list of areas
        expect(page).to have_content('San Francisco Area')

        # Test the area removal
        click_js_link 'Remove Area'
        expect(page).to have_no_content('San Francisco Area')
      end
    end

    scenario 'should be able to deactivate places from areas assigned to the campaign' do
      Kpi.create_global_kpis
      area = create(:area, name: 'San Francisco Area', company: company)
      place1 = create(:place, name: 'One place name')
      place2 = create(:place, name: 'Another place name')
      area.places << [place1, place2]

      campaign.areas << [area]
      visit campaign_path(campaign)

      tab = open_tab('Places')

      within tab do
        expect(page).to have_content('San Francisco Area')
        find('a[data-original-title="Customize area"]').click # tooltip changes the title
      end

      within visible_modal do
        expect(page).to have_content('Customize San Francisco Area')
        expect(page).to have_content 'One place name'
        expect(page).to have_content 'Another place name'
        fill_in 'q', with: 'one'
        expect(page).not_to have_content 'Another place name'
        within(resource_item("#area-campaign-place-#{place1.id}")) { click_js_link 'Deactivate' }
        expect(page).to have_selector("#area-campaign-place-#{place1.id}.inactive")
      end

      expect(campaign.areas_campaigns.find_by(area_id: area.id).exclusions).to eql [place1.id]
    end

    scenario 'should be able to include places to areas assigned to the campaign' do
      expect_any_instance_of(CombinedSearch).to receive(:open).and_return(double(read: { results:
        [
          { reference: 'xxxxx', place_id: '1111', name: 'Walt Disney World Dolphin', formatted_address: '123 Blvr' }
        ]
      }.to_json))
      expect_any_instance_of(GooglePlaces::Client).to receive(:spot).with('xxxxx').and_return(double(
        name: 'Walt Disney World Dolphin', formatted_address: '123 Blvr', address_components: nil,
        lat: '1.1111', lng: '2.2222', types: ['establishment']
      ))
      Kpi.create_global_kpis
      area = create(:area, name: 'Orlando', company: company)

      campaign.areas << [area]
      visit campaign_path(campaign)

      tab = open_tab('Places')

      within tab do
        expect(page).to have_content('Orlando')
        find('a[data-original-title="Customize area"]').click # tooltip changes the title
      end

      within visible_modal do
        expect(page).to have_content('Customize Orlando Area')
        click_js_link('Add new place')
      end

      within visible_modal do
        expect(page).to have_content('New Place')
        select_from_autocomplete 'Search for a place', 'Walt Disney World Dolphin'
        click_js_button 'Add'
      end

      expect(page).to_not have_selector('h3', text: 'New Place')
      expect(page).to have_selector('h3', text: 'Customize Orlando Area')
      new_place_id = Place.last.id
      expect(campaign.areas_campaigns.find_by(area_id: area.id).inclusions).to eql [new_place_id]

      within visible_modal do
        expect(page).to have_content('Customize Orlando Area')
        expect(page).to have_content('Walt Disney World Dolphin')
        within(resource_item("#area-campaign-place-#{new_place_id}")) { click_js_link 'Deactivate' }
        expect(page).to have_selector("#area-campaign-place-#{new_place_id}.inactive")
        click_js_button('Done')
      end
      ensure_modal_was_closed

      within tab do
        find('a[data-original-title="Customize area"]').click # tooltip changes the title
      end

      within visible_modal do
        expect(page).to have_content('Customize Orlando Area')
        expect(page).to have_no_content('Walt Disney World Dolphin')
      end
    end

    scenario 'confirm from user to include existing places to areas assigned to the campaign' do
      expect_any_instance_of(CombinedSearch).to receive(:open).and_return(double(read: { results:
        [
          { reference: '1111', place_id: '1111', name: 'Walt Disney World Dolphin', formatted_address: '123 Blvr' }
        ]
      }.to_json))
      Kpi.create_global_kpis

      area = create(:area, name: 'Orlando', company: company)
      another_area = create(:area, name: 'Florida', company: company)
      another_area.places << create(:place, place_id: '1111', reference: '1111', name: 'Walt Disney World Dolphin')

      campaign.areas << [area, another_area]
      visit campaign_path(campaign)

      tab = open_tab('Places')

      within tab do
        expect(page).to have_content('Orlando')
        find("a#customize_area_#{area.id}").click # tooltip changes the title
      end

      within visible_modal do
        expect(page).to have_content('Customize Orlando Area')
        click_js_link('Add new place')
      end

      within visible_modal do
        expect(page).to have_content('New Place')
        select_from_autocomplete 'Search for a place', 'Walt Disney World Dolphin'
        click_js_button 'Add'
      end

      within visible_modal do
        expect(page).to have_content('Are you sure you want to add this Place? This Place has already been added to the following Area(s): Florida')
        click_js_link('OK')
      end

      wait_for_ajax
      new_place_id = Place.last.id
      expect(campaign.areas_campaigns.find_by(area_id: area.id).inclusions).to eql [new_place_id]

      within visible_modal do
        expect(page).to have_content('Customize Orlando Area')
        expect(page).to have_content('Walt Disney World Dolphin')
        within(resource_item("#area-campaign-place-#{new_place_id}")) { click_js_link 'Deactivate' }
        expect(page).to have_selector("#area-campaign-place-#{new_place_id}.inactive")
        click_js_button('Done')
      end
      ensure_modal_was_closed

      within tab do
        find("a#customize_area_#{area.id}").click # tooltip changes the title
      end

      within visible_modal do
        expect(page).to have_content('Customize Orlando Area')
        expect(page).to have_no_content('Walt Disney World Dolphin')
      end
    end

    feature 'Add KPIs', search: false do

      feature 'with a non admin user', search: false do
        let(:company) { create(:company) }
        let(:user) { create(:user, company: company, role_id: create(:non_admin_role, company: company).id) }
        let(:company_user) { user.company_users.first }

        scenario 'User without permissions cannot add KPIs' do
          company_user.role.permissions.create(action: :show, subject_class: 'Campaign', mode: 'campaigns')
          company_user.role.permissions.create(action: :view_kpis, subject_class: 'Campaign', mode: 'campaigns')

          campaign = create(:campaign, company: company)
          visit campaign_path(campaign)

          open_tab('KPIs')

          expect(page).to_not have_content('Add KPI')
        end
      end

      scenario 'Add existing KPI to campaign' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: company)

        visit campaign_path(campaign)

        tab = open_tab('KPIs')

        click_js_link 'Add KPI'

        within visible_modal do
          fill_in 'Search', with: 'Gender'
          expect(page).to have_content('Gender')
          expect(page).to have_no_content('Events')
          within(resource_item(Kpi.gender)) { click_js_link 'Add KPI' }
          expect(page).to have_no_content('Gender') # The KPI was removed from the available KPIs list
        end
        close_modal

        click_js_link 'Add KPI'

        within visible_modal do
          expect(page).to have_no_content('Gender') # The KPI does not longer appear on the list after it was added to the campaign
          expect(page).to have_content('Comments')
        end
        close_modal

        within tab do
          # Ensure the KPI now appears on the list of KPIs
          expect(page).to have_content('Gender')
        end
      end

      scenario 'Add a new KPI to campaign and set the goal' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: company)

        visit campaign_path(campaign)

        open_tab('KPIs')

        click_js_link 'Add KPI'

        within visible_modal do
          click_js_link 'Create New KPI'
        end

        within visible_modal do
          fill_in 'Name', with: 'My Custom KPI'
          fill_in 'Description', with: 'My custom KPI description'
          select_from_chosen('Count', from: 'Kpi type', match: :first)
          click_js_link 'Add a segment'
          fill_in 'Segment name', with: 'Option 1'
          select_from_chosen('Dropdown', from: 'Capture mechanism', match: :first)
          click_js_button 'Create'
        end
        ensure_modal_was_closed

        kpi = Kpi.last
        within '#global-kpis' do
          expect(page).to have_content('My Custom KPI')
          expect(page).to have_content('My custom KPI description')
          hover_and_click('#campaign-kpi-' + kpi.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Goal', with: '223311'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('223311.0')
        end
      end

      scenario 'Get errors when create a new KPI without enough segments for the selected capture mechanism' do
        campaign = create(:campaign, company: company)

        visit campaign_path(campaign)

        click_js_link 'KPIs'

        click_js_link 'Add KPI'

        within visible_modal do
          click_js_link 'Create New KPI'
        end

        within visible_modal do
          fill_in 'Name', with: 'My Custom KPI'
          fill_in 'Description', with: 'my custom kpi description'
          select_from_chosen('Count', from: 'Kpi type', match: :first)
          click_js_link 'Add a segment'
          fill_in 'Segment name', with: 'Option 1'
          select_from_chosen('Radio', from: 'Capture mechanism', match: :first)
          click_js_button 'Create'
          expect(page).to have_content('You need to add at least 2 segments for the selected capture mechanism')
        end
      end
    end

    feature 'Remove KPIs' do
      scenario 'Remove existing KPI from campaign' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: company)
        kpi = create(:kpi, name: 'My Custom KPI', description: 'My custom kpi description',
          kpi_type: 'number', capture_mechanism: 'currency', company: company)
        campaign.add_kpi kpi

        visit campaign_path(campaign)

        open_tab('KPIs')

        within '#global-kpis' do
          expect(page).to have_content('My Custom KPI')
          hover_and_click('#campaign-kpi-' + kpi.id.to_s, 'Remove')
        end

        confirm_prompt 'Please confirm you want to remove this KPI?'

        within '#global-kpis' do
          expect(page).to have_no_content('My Custom KPI')
        end

        # Ensure that Campaign-KPI association was removed
        visit campaign_path(campaign)

        open_tab('KPIs')

        within '#global-kpis' do
          expect(page).to have_no_content('My Custom KPI')
        end
      end
    end

    feature 'Edit custom KPIs', search: false do

      feature 'with a non admin user', search: false do
        let(:company) { create(:company) }
        let(:user) { create(:user, company: company, role_id: create(:non_admin_role, company: company).id) }
        let(:company_user) { user.company_users.first }
        let(:campaign) { create(:campaign, company: company) }
        let(:kpi) do
          create(:kpi, name: 'My Custom KPI', description: 'my custom kpi description',
            kpi_type: 'number', capture_mechanism: 'currency', company: company)
        end

        scenario 'User without permissions cannot edit Custom KPIs' do
          Kpi.create_global_kpis
          company_user.role.permissions.create(action: :show, subject_class: 'Campaign', mode: 'campaigns')
          company_user.role.permissions.create(action: :view_kpis, subject_class: 'Campaign', mode: 'campaigns')

          campaign.add_kpi(kpi)

          visit campaign_path(campaign)

          within '#global-kpis' do
            expect(page).to have_content('My Custom KPI')
            hover_and_click('#campaign-kpi-' + kpi.id.to_s, 'Edit')
          end

          within visible_modal do
            expect(page).to have_content('You are not authorized to perform this action')
          end
        end

        scenario 'User without permissions to edit Custom KPIs and permission to edit goals' do
          Kpi.create_global_kpis
          company_user.role.permissions.create(action: :show, subject_class: 'Campaign', mode: 'campaigns')
          company_user.role.permissions.create(action: :view_kpis, subject_class: 'Campaign', mode: 'campaigns')
          company_user.role.permissions.create(action: :edit_kpi_goals, subject_class: 'Campaign', mode: 'campaigns')

          campaign.add_kpi(kpi)
          create(:goal, goalable: campaign, kpi: kpi, value: 100)

          visit campaign_path(campaign)

          within '#global-kpis' do
            expect(page).to have_content('My Custom KPI')
            expect(page).to have_content('100.0')
            expect(page).to have_content('my custom kpi description')
            hover_and_click('#campaign-kpi-' + kpi.id.to_s, 'Edit')
          end

          within visible_modal do
            find_field('Name', disabled: true)
            find_field('Description', disabled: true)
            find_field('Kpi type', visible: false, disabled: true)
            find_field('Capture mechanism', visible: false, disabled: true)
            fill_in 'Goal', with: '350'
            click_js_button 'Save'
          end
          ensure_modal_was_closed

          within '#global-kpis' do
            expect(page).to have_content('350.0')
          end
        end
      end

      scenario 'Edit Custom KPI' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: company)
        kpi = create(:kpi, name: 'My Custom KPI', description: 'my custom kpi description',
          kpi_type: 'number', capture_mechanism: 'currency', company: company)
        campaign.add_kpi(kpi)
        create(:goal, goalable: campaign, kpi: kpi, value: 100)

        visit campaign_path(campaign)

        click_js_link 'KPIs'

        within '#global-kpis' do
          expect(page).to have_content('My Custom KPI')
          hover_and_click('#campaign-kpi-' + kpi.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Name', with: 'My Modified KPI'
          fill_in 'Description', with: 'my modified kpi description'
          select_from_chosen('Count', from: 'Kpi type', match: :first)
          click_js_link 'Add a segment'
          fill_in 'Segment name', with: 'Option 1'
          select_from_chosen('Dropdown', from: 'Capture mechanism', match: :first)
          click_js_button 'Save'
        end
        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('My Modified KPI')
          expect(page).to have_content('my modified kpi description')
          hover_and_click('#campaign-kpi-' + kpi.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Goal', with: '350'
          click_js_button 'Save'
        end
        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('350.0')
        end
      end
    end

    feature 'Activity Types', search: false do
      scenario 'Set goals for Activity Types' do
        campaign = create(:campaign, company: company)
        activity_type = create(:activity_type, name: 'Activity Type #1', company: company)

        visit campaign_path(campaign)

        click_js_link 'KPIs'

        click_js_link 'Add KPI'

        within visible_modal do
          expect(page).to have_content('Add KPI')
          fill_in 'Search', with: 'Activity Type #1'
          within '.resource-list' do
            expect(page).to have_content('Activity Type #1')
            hover_and_click '.resource-item', 'Add Activity Type'
            expect(page).not_to have_content('Activity Type #1')
          end
        end
        close_modal

        # Reopen the modal and make sure the activity type is not there
        click_js_link 'Add KPI'
        within visible_modal do
          expect(page).to have_content('Add KPI')
          fill_in 'Search', with: 'Activity Type #1'
          within '.select-list' do
            expect(page).not_to have_content('Activity Type #1')
          end
        end
        close_modal

        within '#global-kpis' do
          expect(page).to have_content('Activity Type #1')
          hover_and_click('#campaign-activity-type-' + activity_type.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Goal', with: '123'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('123.0')

          # Remove the activity type from the list
          expect(page).to have_content('Activity Type #1')
          hover_and_click('#campaign-activity-type-' + activity_type.id.to_s, 'Remove')

          expect(page).not_to have_content('Activity Type #1')
        end

        # Reopen the modal and make sure the activity type is againg available to be added
        click_js_link 'Add KPI'
        within visible_modal do
          expect(page).to have_content('Add KPI')
          fill_in 'Search', with: 'Activity Type #1'
          within '.select-list' do
            expect(page).to have_content('Activity Type #1')
          end
        end
      end
    end

    feature 'Documents' do
      scenario 'A user can upload a document to the Campaign' do
        with_resque do
          visit campaign_path(campaign)
          click_js_link 'Documents'

          within '#documents_upload_form' do
            attach_file 'file', 'spec/fixtures/file.pdf'
            wait_for_ajax(30) # For the file to upload to S3
          end
          expect(page).to_not have_content('DRAG & DROP')

          document = AttachedAsset.last

          # Check that the document appears is in the document list
          within '#documents-list' do
            src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
            expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
          end

          expect(document.attachable).to eql(campaign)

          # Make sure the document is still there after reloading page
          visit current_path
          click_js_link 'Documents'

          # Check that the image appears on the page
          within '#documents-list' do
            src = document.file.url(:original, timestamp: false).gsub(/\Ahttp(s)?/, 'https')
            expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]", wait: 10)
          end

          # Delete the document
          within '#documents-list' do
            hover_and_click '.resource-item', 'Delete'
          end
          confirm_prompt 'Are you sure you want to delete this document?'

          # Check that the document was removed
          within '#documents-list' do
            expect(page).not_to have_selector '.resource-item'
          end
        end
      end
    end
  end

  feature 'custom filters', search: true, js: true do
    it_behaves_like 'a list that allow saving custom filters' do
      let!(:brand1) { create(:brand, name: 'Brand 1', company: company) }
      let!(:brand2) { create(:brand, name: 'Brand 2', company: company) }

      before do
        campaign = create(:campaign, company: company)
        campaign.brands << brand1
        campaign.brands << brand2
        company_user.brands << brand1
        company_user.brands << brand2
        company_user.campaigns << campaign

        create(:brand_portfolio, name: 'A Vinos Ticos', description: 'Algunos vinos de Costa Rica', company: company)
        create(:brand_portfolio, name: 'B Licores Costarricenses', description: 'Licores ticos', company: company)
      end

      let(:list_url) { campaigns_path }

      let(:filters) do
        [{ section: 'BRANDS', item: 'Brand 1' },
         { section: 'BRANDS', item: 'Brand 2' },
         { section: 'PEOPLE', item: user.full_name },
         { section: 'BRAND PORTFOLIOS', item: 'A Vinos Ticos' },
         { section: 'ACTIVE STATE', item: 'Inactive' }]
      end
    end
  end

  feature 'export', search: true do
    let(:campaign1) { create(:campaign, name: 'Cacique FY13',
                                description: 'Test campaign for guaro Cacique', company: company) }
    let(:campaign2) { create(:campaign, name: 'New Brand Campaign',
                                description: 'Campaign for another brand', company: company) }

    before do
      create(:event, start_date: '08/21/2013', end_date: '08/21/2013',
             start_time: '10:00am', end_time: '11:00am', campaign: campaign1)
      create(:event, start_date: '08/28/2013', end_date: '08/29/2013',
             start_time: '11:00am', end_time: '12:00pm', campaign: campaign1)
      create(:event, start_date: '09/18/2013', end_date: '09/18/2013',
             start_time: '11:00am', end_time: '12:00pm', campaign: campaign2)
      Sunspot.commit
    end

    scenario 'should be able to export as CSV' do
      visit campaigns_path

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'FIRST EVENT', 'LAST EVENT', 'ACTIVE STATE'],
        ['Cacique FY13', 'Test campaign for guaro Cacique', '08/21/2013 10:00', '08/28/2013 11:00', 'Active'],
        ['New Brand Campaign', 'Campaign for another brand', '09/18/2013 11:00', '09/18/2013 11:00', 'Active']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit campaigns_path

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
        expect(text).to include 'Campaigns'
        expect(text).to include 'CaciqueFY13'
        expect(text).to include 'TestcampaignforguaroCacique'
        expect(text).to include 'WEDAug21,2013'
        expect(text).to include 'WEDAug28,2013T'
        expect(text).to include 'NewBrandCampaign'
        expect(text).to include 'Campaignforanotherbrand'
        expect(text).to include 'WEDSep18,2013'
      end
    end
  end

  feature 'admin user', js: true do
    it_behaves_like 'a user that can add staff to campaigns'
  end

  feature 'non admin user', js: true do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can add staff to campaigns' do
      before { company_user.campaigns << campaign }
      let(:permissions) { [[:show, 'Campaign'], [:view_staff, 'Campaign'], [:add_staff, 'Campaign']] }
    end
  end

  def campaigns_list
    '#campaigns-list'
  end

end
