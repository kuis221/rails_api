require 'rails_helper'
require 'open-uri'

feature "Reports", js: true do
  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in @user
    @company = @user.companies.first
    page.driver.resize(1024, 1000)
  end

  after do
    Warden.test_reset!
  end

  feature "Create a report" do
    scenario 'user is redirected to the report build page after creation' do
      visit results_reports_path

      click_js_button 'New Report'

      expect {
        within visible_modal do
          fill_in 'Name', with: 'new report name'
          fill_in 'Description', with: 'new report description'
          click_button 'Create'
        end
        ensure_modal_was_closed
      }.to change(Report, :count).by(1)
      report = Report.last

      expect(current_path).to eql(build_results_report_path(report))
    end
  end

  scenario "allows the user to activate/deactivate reports" do
    FactoryGirl.create(:report, name: 'Events by Venue',
      description: 'a resume of events by venue',
      active: true, company: @company)

    visit results_reports_path

    within reports_list do
      expect(page).to have_content('Events by Venue')
      hover_and_click 'li', 'Deactivate'
    end

    confirm_prompt "Are you sure you want to deactivate this report?"

    within reports_list do
      expect(page).to have_no_content('Events by Venue')
    end
  end

  scenario "allows the user to edit reports name and description" do
    report = FactoryGirl.create(:report, name: 'My Report',
      description: 'Description of my report',
      active: true, company: @company)

    visit results_reports_path

    within reports_list do
      expect(page).to have_content('My Report')
      hover_and_click 'li', 'Edit'
    end

    within visible_modal do
      fill_in 'Name', with: 'Edited Report Name'
      fill_in 'Description', with: 'Edited Report Description'
      click_js_button 'Save'
    end

    within reports_list do
      expect(page).to have_selector('b', text: 'Edited Report Name')
      expect(page).to have_selector('p', text: 'Edited Report Description')
    end
  end

  feature "video tutorial" do
    scenario "a user can play and dismiss the video tutorial" do
      visit results_reports_path

      feature_name = 'Getting Started: Results Overview'

      expect(page).to have_content(feature_name)
      expect(page).to have_content('The Results Module holds all of your post-event data results')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit results_reports_path
      expect(page).to have_no_content(feature_name)
    end
  end

  feature "run view" do
    let(:report) { FactoryGirl.create(:report, name: 'My Report',
        description: 'Description of my report',
        active: true, company: @company) }

    scenario "a user can play and dismiss the video tutorial" do
      visit results_report_path(report)

      feature_name = 'Getting Started: Custom Reports'

      expect(page).to have_content(feature_name)
      expect(page).to have_content("Custom Reports are reports that either you or your teammates created and shared")
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit results_report_path(report)
      expect(page).to have_no_content(feature_name)
    end

    scenario "allows the user to modify an existing custom report" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit results_report_path(report)

      click_link 'Edit'

      expect(current_path).to eql(build_results_report_path(report))

      within ".sidebar" do
        find("li", text: 'Kpi #1').drag_to field_list('columns')
        expect(field_list('fields')).to have_no_content('Kpi #1')
      end

      click_button 'Save'

      expect(current_path).to eql(build_results_report_path(report))
    end

    scenario "allows the user to cancel changes an existing custom report" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit results_report_path(report)

      click_link 'Edit'

      expect(current_path).to eql(build_results_report_path(report))

      within ".sidebar" do
        find("li", text: 'Kpi #1').drag_to field_list('columns')
        expect(field_list('fields')).to have_no_content('Kpi #1')
      end

      page.execute_script('$(window).off("beforeunload")') # Prevent the alert as there is no way to test it
      click_link 'Exit'

      expect(current_path).to eql(results_report_path(report))
    end

    it "should display a message if the report returns not results" do
      Kpi.create_global_kpis
      report = FactoryGirl.create(:report,
        company: @company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"place:name", "label"=>"Venue Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )

      visit results_report_path(report)

      within report_preview do
        expect(page).to have_no_content('Drag and drop filters, columns, rows and values to create your report.')
        # The report should not display the table header
        expect(page).to have_no_content('IMPRESSIONS')
        expect(page).to have_no_content('INTERACTIONS')

        expect(page).to have_content('There are no results matching the filtering criteria you selected.')
        expect(page).to have_content('Please select different filtering criteria.')
      end
    end

    scenario "should render the report" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, name: 'Bar 1'),
        results: {impressions: 123, interactions: 50})

      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, name: 'Bar 2'),
        results: {impressions: 321, interactions: 25})

      report = FactoryGirl.create(:report,
        company: @company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"place:name", "label"=>"Venue Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )

      visit results_report_path(report)

      expect(page).to have_content('GRAND TOTAL: 444')
      expect(page).to have_content('Bar 1 123.0')
      expect(page).to have_content('Bar 2 321.0')

      # Export the report
      download_report

      export = ListExport.last
      csv_rows = CSV.parse(open(export.file.url).read)
      expect(csv_rows[0]).to eql ['Venue Name', 'Impressions']
      expect(csv_rows[1]).to eql ['Bar 1', '123.00']
      expect(csv_rows[2]).to eql ['Bar 2', '321.00']
      export.destroy
    end

    scenario "a report with two rows with expand/collapse functionality" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      FactoryGirl.create(:event, campaign: campaign,
        start_date: '01/21/2013', end_date: '01/21/2013', place: FactoryGirl.create(:place, name: 'Bar 1'),
        results: {impressions: 123, interactions: 50})

      FactoryGirl.create(:event, campaign: campaign,
        start_date: '02/13/2013', end_date: '02/13/2013', place: FactoryGirl.create(:place, name: 'Bar 2'),
        results: {impressions: 321, interactions: 25})

      report = FactoryGirl.create(:report,
        company: @company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"place:name", "label"=>"Venue Name"},
                  {"field"=>"event:start_date", "label"=>"Start Date"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )

      visit results_report_path(report)

      expect(page).to have_content('GRAND TOTAL: 444')
      expect(page).to have_content('Bar 1 123.0')
      expect(page).to have_content('Bar 2 321.0')

      # Test the expand/collapse logic
      within report_preview do
        # Initial state should be collapsed
        expect(page).to have_content('2013/01/21')
        expect(page).to have_content('2013/02/13')
        find('.report-table.cloned a.expand-all').trigger 'click'
        expect(page).to have_no_content('2013/01/21')
        expect(page).to have_no_content('2013/02/13')
        find('.report-table.cloned a.expand-all').trigger 'click'
        expect(page).to have_content('2013/01/21')
        expect(page).to have_content('2013/02/13')
      end

      # Export the report
      download_report

      export = ListExport.last
      csv_rows = CSV.parse(open(export.file.url).read)
      expect(csv_rows[0]).to eql ['Venue Name', 'Start Date', 'Impressions']
      expect(csv_rows[1]).to eql ['Bar 1', '2013/01/21', '123.00']
      expect(csv_rows[2]).to eql ['Bar 2', '2013/02/13', '321.00']
      export.destroy
    end

    scenario "a report with values displayed as percentage of row total/grand total/column total" do
      campaign1 = FactoryGirl.create(:campaign, company: @company, name: 'Campaign 1')
      campaign2 = FactoryGirl.create(:campaign, company: @company, name: 'Campaign 2')
      FactoryGirl.create(:event, campaign: campaign1,
        place: FactoryGirl.create(:place, name: 'Bar 1', state: 'State 1'),
        results: {impressions: 300, interactions: 20})

      FactoryGirl.create(:event, campaign: campaign1,
        place: FactoryGirl.create(:place, name: 'Bar 2', state: 'State 2'),
        results: {impressions: 700, interactions: 40})

      FactoryGirl.create(:event, campaign: campaign2,
        place: FactoryGirl.create(:place, name: 'Bar 3', state: 'State 1'),
        results: {impressions: 200, interactions: 80})

      FactoryGirl.create(:event, campaign: campaign2,
        place: FactoryGirl.create(:place, name: 'Bar 4', state: 'State 2'),
        results: {impressions: 100, interactions: 60})

      report = FactoryGirl.create(:report,
        company: @company,
        columns: [{"field"=>"values", "label"=>"Values"},{"field"=>"place:state", "label"=>"State"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign Name"}],
        values:  [
            {"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum", 'display'=>'perc_of_row'},
            {"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions", "aggregate"=>"sum", 'display'=>'perc_of_total', 'precision' => '1' }
        ]
      )

      visit results_report_path(report)

      within report_preview do
        expect(page).to have_content('IMPRESSIONS INTERACTIONS')
        expect(page).to have_content('STATE 1 STATE 2 STATE 1 STATE 2')
        expect(page).to have_content('GRAND TOTAL: 500.00 800.00 100.0 100.0')
        expect(page).to have_content('Campaign 1 30.00% 70.00%  10.0% 20.0%')
        expect(page).to have_content('Campaign 2 66.67% 33.33% 40.0% 30.0%')

        expect(page).to have_no_link('Expand All')
      end

      # Export the report
      download_report

      export = ListExport.last
      csv_rows = CSV.parse(open(export.file.url).read)
      expect(csv_rows[0]).to eql ['Campaign Name', 'Impressions/State 1', 'Impressions/State 2', "Interactions/State 1", "Interactions/State 2"]
      expect(csv_rows[1]).to eql ['Campaign 1', '30.00%', '70.00%', '10.0%', '20.0%']
      expect(csv_rows[2]).to eql ['Campaign 2', '66.67%', '33.33%', '40.0%', '30.0%']
      export.destroy
    end
  end

  feature "build view" do
    before { Kpi.create_global_kpis }

    let(:report) { FactoryGirl.create(:report, name: 'Events by Venue',
        description: 'a resume of events by venue',
        active: true, company: @company) }

    scenario "a user can play and dismiss the video tutorial" do
      visit build_results_report_path(report)

      feature_name = 'Getting Started: Report Builder'

      expect(page).to have_content(feature_name)
      expect(page).to have_content("Let's build a report!")
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit build_results_report_path(report)
      expect(page).to have_no_content(feature_name)
    end

    scenario "share a report" do
      user = FactoryGirl.create(:company_user,
        user: FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas'),
        company: @company)
      team = FactoryGirl.create(:team, name:'Los Fantasticos', company: @company)
      role = FactoryGirl.create(:role, name: 'Super Hero', company: @company)

      visit build_results_report_path(report)
      click_js_button 'Share'
      within visible_modal do
        expect(find_field('report_sharing_custom')['checked']).to be_falsey
        expect(find_field('report_sharing_everyone')['checked']).to be_falsey
        expect(find_field('report_sharing_owner')['checked']).to be_truthy
        choose('Share with Users, Teams and Roles')
        select_from_chosen('Guillermo Vargas', from: 'report_sharing_selections')
        select_from_chosen('Los Fantasticos', from: 'report_sharing_selections')
        select_from_chosen('Super Hero', from: 'report_sharing_selections')
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      click_js_button 'Share'
      within visible_modal do
        expect(page).to have_content('Guillermo Vargas')
        expect(page).to have_content('Los Fantasticos')
        expect(page).to have_content('Super Hero')
        expect(find_field('report_sharing_custom')['checked']).to be_truthy
        expect(find_field('report_sharing_everyone')['checked']).to be_falsey
        expect(find_field('report_sharing_owner')['checked']).to be_falsey

        choose('Share with everyone')
        click_js_button 'Save'
      end
      ensure_modal_was_closed
      expect(report.reload.sharing).to eql 'everyone'
    end

    scenario "search for fields in the fields list" do
      FactoryGirl.create(:kpi, name: 'ABC KPI', company: @company)
      type = FactoryGirl.create(:activity_type, name: 'XYZ Activiy Type', company: @company)
      FactoryGirl.create(:form_field_number, fieldable: type, name: 'FormField 1')
      FactoryGirl.create(:form_field_number, fieldable: type, name: 'FormField 2')

      visit build_results_report_path(report)

      within report_fields do
        expect(page).to have_content('XYZ ACTIVIY TYPE')
        expect(page).to have_content('FormField 1')
        expect(page).to have_content('FormField 2')
        expect(page).to have_content('VENUE')
        expect(page).to have_content('USER')
        expect(page).to have_content('TEAM')
        expect(page).to have_content('ABC KPI')
      end

      fill_in 'field_search', with: 'XYZ'

      within report_fields do
        expect(page).to have_no_content('ABC KPI')
        expect(page).to have_no_content('VENUE')
        expect(page).to have_no_content('USER')
        expect(page).to have_no_content('TEAM')
      end

      fill_in 'field_search', with: 'ABC'

      within report_fields do
        expect(page).to have_content('ABC KPI')
        expect(page).to have_no_content('VENUE')
        expect(page).to have_no_content('USER')
        expect(page).to have_no_content('TEAM')
      end

      fill_in 'field_search', with: 'venue'
      within report_fields do
        expect(page).to have_no_content('ABC')
        expect(page).to have_content('VENUE')
        expect(page).to have_content('Name')
        expect(page).to have_content('State')
        expect(page).to have_content('City')
      end
    end

    scenario "drag fields to the different field lists" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company, description: 'This is the description for kpi#1', kpi_type: 'number')
      FactoryGirl.create(:kpi, name: 'Kpi #2', company: @company, description: 'This is the description for kpi#2',
        kpi_type: 'count', kpis_segments: [
          FactoryGirl.create(:kpis_segment, text: 'First option'),
          FactoryGirl.create(:kpis_segment, text: 'Second option')
        ]
      )
      FactoryGirl.create(:kpi, name: 'Kpi #3', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #4', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #5', company: @company)

      visit build_results_report_path(report)

      # The save button should be disabled
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      # Test the tooltip
      find("li", text: 'Kpi #1').hover
      within('.tooltip') do
        expect(page).to have_content('This is the description for kpi#1')
        expect(page).to have_content('TYPE')
        expect(page).to have_content('Number')
        expect(page).to have_no_content('OPTIONS')
      end

      find("li", text: 'Kpi #2').hover
      within('.tooltip') do
        expect(page).to have_content('This is the description for kpi#2')
        expect(page).to have_content('TYPE')
        expect(page).to have_content('Count')
        expect(page).to have_content('OPTIONS')
        expect(page).to have_content('First option, Second option')
      end

      within ".sidebar" do
        expect(field_list('columns')).to have_no_content('Values')
        find("li", text: 'Kpi #1').drag_to field_list('values')
        expect(field_list('fields')).to have_no_content('Kpi #1')
        find("li", text: 'Kpi #2').drag_to field_list('rows')
        expect(field_list('fields')).to have_no_content('Kpi #2')
        find('li[data-group="Venue"]', text: 'Name').drag_to field_list('rows')
        expect(field_list('rows')).to have_content('Venue Name')
        find("li", text: 'Kpi #3').drag_to field_list('filters')
        expect(field_list('fields')).to have_no_content('Kpi #3')
        find("li", text: 'Kpi #4').drag_to field_list('values')
        expect(field_list('fields')).to have_no_content('Kpi #4')
        expect(field_list('values')).to have_content('Sum of Kpi #4')
        expect(field_list('columns')).to have_content('Values')
      end

      # Save the report and reload page to make sure they were correctly saved
      click_js_button "Save"
      wait_for_ajax
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      visit build_results_report_path(report)
      within ".sidebar" do
        # Each KPI should be in the correct list
        expect(field_list('values')).to have_content('Kpi #1')
        expect(field_list('columns')).to have_content('Values')
        expect(field_list('rows')).to have_content('Kpi #2')
        expect(field_list('filters')).to have_content('Kpi #3')
        expect(field_list('values')).to have_content('Sum of Kpi #4')

        # and they should not be in the source fields lists
        expect(field_list('fields')).to have_no_content('Kpi #1')
        expect(field_list('fields')).to have_no_content('Kpi #2')
        expect(field_list('fields')).to have_no_content('Kpi #3')
        expect(field_list('fields')).to have_no_content('Kpi #4')
        expect(field_list('fields')).to have_content('Kpi #5')
      end
    end

    scenario "user can add fields to the different field lists using the context menu" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #2', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #3', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #4', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #5', company: @company)

      visit build_results_report_path(report)

      # The save button should be disabled
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      within ".sidebar" do
        expect(field_list('columns')).to have_no_content('Values')
        within(field_context_menu 'Kpi #1') { click_js_link 'Add to Values' }
        expect(field_list('fields')).to have_no_content('Kpi #1')
        expect(field_list('values')).to have_content('Kpi #1')
        expect(field_list('columns')).to have_content('Values')

        within(field_context_menu 'Kpi #2') { click_js_link 'Add to Columns' }
        expect(field_list('fields')).to have_no_content('Kpi #2')
        expect(field_list('columns')).to have_content('Kpi #2')

        within(field_context_menu 'Kpi #3') { click_js_link 'Add to Filters' }
        expect(field_list('fields')).to have_no_content('Kpi #3')
        expect(field_list('filters')).to have_content('Kpi #3')

        within(field_context_menu 'Kpi #4') { click_js_link 'Add to Rows' }
        expect(field_list('fields')).to have_no_content('Kpi #4')
        expect(field_list('rows')).to have_content('Kpi #4')
      end

      # Save the report and reload page to make sure they were correctly saved
      click_js_button "Save"
      wait_for_ajax
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      visit build_results_report_path(report)
      within ".sidebar" do
        # Each KPI should be in the correct list
        expect(field_list('values')).to have_content('Sum of Kpi #1')
        expect(field_list('columns')).to have_content('Values')
        expect(field_list('columns')).to have_content('Kpi #2')
        expect(field_list('filters')).to have_content('Kpi #3')
        expect(field_list('rows')).to have_content('Kpi #4')

        # and they should not be in the source fields lists
        expect(field_list('fields')).to have_no_content('Kpi #1')
        expect(field_list('fields')).to have_no_content('Kpi #2')
        expect(field_list('fields')).to have_no_content('Kpi #3')
        expect(field_list('fields')).to have_no_content('Kpi #4')
      end
    end

    scenario "user can change the aggregation method for values" do
      visit build_results_report_path(report)
      field_list('fields').find("li", text: 'Impressions').drag_to field_list('values')
      field_list('values').find('li').click
      within ".report-field-settings" do
        select_from_chosen('Average', from: 'Summarize by')
        expect(find_field('Label').value).to eq('Average of Impressions')
      end
      find('body').click
      click_button 'Save'
      wait_for_ajax
      expect(report.reload.values.first.to_hash).to include("label"=>"Average of Impressions", "aggregate" => 'avg')
    end

    scenario "'Values' must be added automatically to the columns when adding a value" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit build_results_report_path(report)

      within ".sidebar" do
        expect(field_list('columns')).to have_no_content('Values')
        find("li", text: 'Kpi #1').drag_to field_list('values')
        expect(field_list('columns')).to have_content('Values')

        # The 'Values' field cannot be dragged to the list of values
        field_list('columns').find("li", text: 'Values').drag_to field_list('values')
        expect(field_list('columns')).to have_selector("li", text: 'Values', count: 1)
        expect(field_list('values')).to have_no_content('Values')

        # The 'Values' field cannot be dragged to the list of rows
        field_list('columns').find("li", text: 'Values').drag_to field_list('rows')
        expect(field_list('columns')).to have_selector("li", text: 'Values', count: 1)
        expect(field_list('rows')).to have_no_content('Values')

        # The 'Values' field cannot be dragged to the list of filters
        field_list('columns').find("li", text: 'Values').drag_to field_list('filters')
        expect(field_list('columns')).to have_selector("li", text: 'Values', count: 1)
        expect(field_list('filters')).to have_no_content('Values')
      end
    end

    scenario "user can change the aggregation method for rows" do
      campaign = FactoryGirl.create(:campaign, company: @company, name: 'My Super Campaign')
      FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2014', end_date: '01/01/2014',
        results: {impressions: 100, interactions: 1000})
      FactoryGirl.create(:event, campaign: campaign, start_date: '02/02/2014', end_date: '02/02/2014',
        results: {impressions: 50, interactions: 2000})
      visit build_results_report_path(report)
      field_list('fields').find('li[data-field-id="campaign:name"]').drag_to field_list('rows')
      expect(field_list('rows')).to have_content('Campaign Name')
      field_list('fields').find('li[data-field-id="event:start_date"]').drag_to field_list('rows')
      expect(field_list('rows')).to have_content('Event Start date')
      field_list('fields').find("li", text: 'Impressions').drag_to field_list('values')
      field_list('fields').find("li", text: 'Interactions').drag_to field_list('values')

      field_list('rows').find('li[data-field-id="campaign:name"]').click
      within '.report-field-settings' do
        select_from_chosen('Average', from: 'Summarize by')
        expect(find_field('Label').value).to eql 'Campaign Name'
      end
      find('body').click
      click_button 'Save'
      wait_for_ajax
      expect(report.reload.rows.first.to_hash).to include("label"=>"Campaign Name", "aggregate" => 'avg', "field" => "campaign:name")

      within "#report-container tr.level_0" do
        expect(page).to have_content('My Super Campaign')
        expect(page).to have_content('75.00')
        expect(page).to have_content('1,500.00')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').click
      within '.report-field-settings' do
        select_from_chosen('Max', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('100.00')
        expect(page).to have_content('2,000.00')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').click
      within '.report-field-settings' do
        select_from_chosen('Min', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('50.00')
        expect(page).to have_content('1,000.00')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').click
      within '.report-field-settings' do
        select_from_chosen('Sum', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('150.00')
        expect(page).to have_content('3,000.00')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').click
      within '.report-field-settings' do
        select_from_chosen('Count', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('2')
      end
    end

    scenario "user can change the calculation method for values" do
      campaign = FactoryGirl.create(:campaign, company: @company, name: 'My Super Campaign')
      FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2014', end_date: '01/01/2014',
        results: {impressions: 100, interactions: 1000})
      FactoryGirl.create(:event, campaign: campaign, start_date: '02/02/2014', end_date: '02/02/2014',
        results: {impressions: 50, interactions: 2000})
      visit build_results_report_path(report)
      field_list('fields').find('li[data-field-id="campaign:name"]').drag_to field_list('rows')
      field_list('fields').find("li", text: 'Interactions').drag_to field_list('values')

      field_list('values').find('li', text: 'Sum of Interactions').click
      within '.report-field-settings' do
        select_from_chosen('% of Column', from: 'Display as')
        expect(find_field('Label').value).to eql 'Sum of Interactions'
      end
      find('body').click
      click_button 'Save'
      wait_for_ajax
      expect(report.reload.values.first.to_hash).to include("label"=>"Sum of Interactions", "display" => 'perc_of_column', "field" => "kpi:#{Kpi.interactions.id}")

      within "#report-container tr.level_0" do
        expect(page).to have_content('My Super Campaign')
        expect(page).to have_content('100.0')
      end

    end

    scenario "drag fields outside the list to remove it" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit build_results_report_path(report)

      # The save button should be disabled
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      find("li", text: 'Kpi #1').drag_to field_list('columns')
      find_button('Save') # The button should become active

      # Drag the field to outside the list make check it's removed from the columns list
      # and visible in the source fields list
      field_list('columns').find("li", text: 'Kpi #1').drag_to find('#report-container')
      expect(field_list('columns')).to have_no_content('Kpi #1')
      expect(field_list('fields')).to have_content('Kpi #1')
    end

    scenario "user can remove a field by clicking on the X" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit build_results_report_path(report)

      # The save button should be disabled
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      find("li", text: 'Kpi #1').drag_to field_list('columns')
      find_button('Save') # The button should become active

      # Drag the field to outside the list make check it's removed from the columns list
      # and visible in the source fields list
      hover_and_click "#report-columns li", 'Remove'
      expect(field_list('columns')).to have_no_content('Kpi #1')
      expect(field_list('fields')).to have_content('Kpi #1')
    end

    scenario "adding a value should automatically add the 'Values' column and removing it should remove the values" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit build_results_report_path(report)

      find("li", text: 'Kpi #1').drag_to field_list('values')

      # A "Values" field should have been created in the columns list
      expect(field_list('columns')).to have_content('Values')
      expect(field_list('values')).to have_content('Kpi #1')

      # Drop out the "Values" field from the columns and make sure the values are removed
      # from the values list
      field_list('columns').find("li", text: 'Values').drag_to find('#report-container')
      expect(field_list('columns')).to have_no_content('Values')
      expect(field_list('values')).to have_no_content('Kpi #1')
    end

    feature "preview" do
      it "should display a preview as the user make changes on the report" do
        FactoryGirl.create(:event, place: FactoryGirl.create(:place, name: 'Los Pollitos Bar'), company: @company, results: {impressions: 100})
        visit build_results_report_path(report)

        expect(find(report_preview)).to have_content('Drag and drop filters, columns, rows and values to create your report.')

        field_list('fields').find("li", text: 'Impression').drag_to field_list('values')
        field_list('fields').find("li", text: 'Interactions').drag_to field_list('values')

        expect(find(report_preview)).to have_content('Drag and drop filters, columns, rows and values to create your report.')

        field_list('fields').find('li[data-field-id="place:name"]').drag_to field_list('rows')

        within report_preview do
          expect(page).to have_no_content('Drag and drop filters, columns, rows and values to create your report.')
          expect(page).to have_selector('th', text: 'IMPRESSIONS')
          expect(page).to have_selector('th', text: 'INTERACTIONS')
          expect(page).to have_content('Los Pollitos Bar')
        end
      end
    end
  end


  def reports_list
    "ul#custom-reports-list"
  end

  def report_fields
    "#report-fields"
  end

  def field_search_box
    "#field-search-input"
  end

  def report_preview
    "#report-container"
  end

  def field_list(name)
    find("#report-#{name}")
  end

  def field_context_menu(field_name)
    find('.sidebar li.report-field', text: field_name).click
    find(:xpath, "//body").find("div.report-field-settings")
  end

  def download_report
    with_resque do
      wait_for_download_to_complete 25 do
        click_js_button 'Download'
      end
    end
  end
end