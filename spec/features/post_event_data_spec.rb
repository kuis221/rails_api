require 'spec_helper'

feature 'Post Event Data' do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { FactoryGirl.create(:event, campaign: campaign, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for "a user with permissions to fill post event data" do
      scenario "should allow the user to fill the event data" do
        Kpi.create_global_kpis
        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes),
          end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign,
          place: place,
          company: company )
        campaign.assign_all_global_kpis

        campaign.add_kpi FactoryGirl.create(:kpi, name: 'Integer field', kpi_type: 'number', capture_mechanism: 'integer')
        campaign.add_kpi FactoryGirl.create(:kpi, name: 'Decimal field', kpi_type: 'number', capture_mechanism: 'decimal')
        campaign.add_kpi FactoryGirl.create(:kpi, name: 'Currency field', kpi_type: 'number', capture_mechanism: 'currency')
        campaign.add_kpi FactoryGirl.create(:kpi, name: 'Radio field', kpi_type: 'count', capture_mechanism: 'radio', kpis_segments: [
            FactoryGirl.create(:kpis_segment, text: 'Radio Option 1'),
            FactoryGirl.create(:kpis_segment, text: 'Radio Option 2')
          ])

        campaign.add_kpi FactoryGirl.create(:kpi, name: 'Checkbox field', kpi_type: 'count', capture_mechanism: 'checkbox', kpis_segments: [
            FactoryGirl.create(:kpis_segment, text: 'Checkbox Option 1'),
            FactoryGirl.create(:kpis_segment, text: 'Checkbox Option 2'),
            FactoryGirl.create(:kpis_segment, text: 'Checkbox Option 3')
          ])

        brand = FactoryGirl.create(:brand, name: 'Cacique', company_id: company.to_param)
        FactoryGirl.create(:marque, name: 'Marque #1 for Cacique', brand: brand)
        FactoryGirl.create(:marque, name: 'Marque #2 for Cacique', brand: brand)
        campaign.brands << brand

        # Create some custom fields of different types
        FactoryGirl.create(:form_field,
          name: 'Custom Single Text',
          type: 'FormField::Text',
          settings: {'range_format' => 'characters', 'range_min' => '5', 'range_max' => '20'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom TextArea',
          type: 'FormField::TextArea',
          settings: {'range_format' => 'words', 'range_min' => '2', 'range_max' => '4'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom Numeric',
          type: 'FormField::Number',
          settings: {'range_format' => 'value', 'range_min' => '5', 'range_max' => '20'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom Currency',
          type: 'FormField::Currency',
          settings: {'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom Summation',
          type: 'FormField::Summation',
          options: [FactoryGirl.create(:form_field_option, name: 'Summation Opt1'), FactoryGirl.create(:form_field_option, name: 'Summation Opt2')],
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom Percentage',
          type: 'FormField::Percentage',
          options: [FactoryGirl.create(:form_field_option, name: 'Percentage Opt1', ordering: 1), FactoryGirl.create(:form_field_option, name: 'Percentage Opt2', ordering: 2)],
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom LikertScale',
          type: 'FormField::LikertScale',
          options: [FactoryGirl.create(:form_field_option, name: 'LikertScale Opt1'), FactoryGirl.create(:form_field_option, name: 'LikertScale Opt2')],
          statements: [FactoryGirl.create(:form_field_statement, name: 'LikertScale Stat1'), FactoryGirl.create(:form_field_statement, name: 'LikertScale Stat2')],
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom Checkbox',
          type: 'FormField::Checkbox',
          options: [FactoryGirl.create(:form_field_option, name: 'Checkbox Opt1', ordering: 1), FactoryGirl.create(:form_field_option, name: 'Checkbox Opt2', ordering: 2)],
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Custom Radio',
          type: 'FormField::Radio',
          options: [FactoryGirl.create(:form_field_option, name: 'Radio Opt1', ordering: 1), FactoryGirl.create(:form_field_option, name: 'Checkbox Opt2', ordering: 2)],
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Brand',
          type: 'FormField::Brand',
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Marque',
          type: 'FormField::Marque',
          fieldable: campaign,
          required: false)

        visit event_path(event)

        fill_in 'Summary', with: 'This is the summary'

        fill_in '< 12', with: '10'
        fill_in '12 – 17', with: '11'
        fill_in '18 – 24', with: '12'
        fill_in '25 – 34', with: '13'
        fill_in '35 – 44', with: '14'
        fill_in '45 – 54', with: '15'
        fill_in '55 – 64', with: '16'
        fill_in '65+', with: '9'

        fill_in 'Asian', with: '20'
        fill_in 'Black / African American', with: '12'
        fill_in 'Hispanic / Latino', with: '13'
        fill_in 'Native American', with: '34'
        fill_in 'White', with: '21'

        fill_in 'Female', with: '34'
        fill_in 'Male', with: '66'

        fill_in 'Impressions',  with: 100
        fill_in 'Interactions', with: 110
        fill_in 'Samples',      with: 120

        fill_in 'Integer field', with: '99'
        fill_in 'Decimal field', with: '99.9'
        fill_in 'Currency field', with: '79.9'

        choose 'Radio Option 1'

        unicheck 'Checkbox Option 1'
        unicheck 'Checkbox Option 2'

        # Fill in the custom (non KPI) fields
        fill_in 'Custom Single Text', with: 'Testing Single'
        fill_in 'Custom TextArea', with: 'Testing Area'
        fill_in 'Custom Numeric', with: '10'
        fill_in 'Custom Currency', with: '30'

        fill_in 'Summation Opt1', with: '100'
        fill_in 'Summation Opt2', with: '200'

        fill_in 'Percentage Opt1', with: '75'
        fill_in 'Percentage Opt2', with: '25'

        unicheck 'Checkbox Opt1'
        unicheck 'Checkbox Opt2'

        choose 'Radio Opt1'

        select_from_chosen('Cacique', from: 'Brand')
        select_from_chosen('Marque #2 for Cacique', from: 'Marque')

        click_button 'Save'

        # Ensure the results are displayed on the page

        within "#ethnicity-graph" do
          expect(page).to have_content "20%"
          expect(page).to have_content "12%"
          expect(page).to have_content "13%"
          expect(page).to have_content "34%"
          expect(page).to have_content "21%"
        end

        within "#gender-graph" do
          expect(page).to have_content "34 %"
          expect(page).to have_content "66 %"
        end

        within "#age-graph" do
          expect(page).to have_content "9%"
          expect(page).to have_content "11%"
          expect(page).to have_content "12%"
          expect(page).to have_content "13%"
          expect(page).to have_content "14%"
          expect(page).to have_content "15%"
          expect(page).to have_content "16%"
        end

        within ".box_metrics" do
          expect(page).to have_content('99 INTEGER FIELD')
          expect(page).to have_content('99.9 DECIMAL FIELD')
          expect(page).to have_content('$79.90 CURRENCY FIELD')
          expect(page).to have_content('$79.90 CURRENCY FIELD')
          expect(page).to have_content('RADIO OPTION 1 RADIO FIELD')
          expect(page).to have_content('CHECKBOX OPTION 1 AND CHECKBOX OPTION 2')
          expect(page).to have_content('CHECKBOX OPT1 AND CHECKBOX OPT2 CUSTOM CHECKBOX')
          expect(page).to have_content('RADIO OPT1 CUSTOM RADIO')
          expect(page).to have_content('TESTING SINGLE CUSTOM SINGLE TEXT')
          expect(page).to have_content('TESTING AREA CUSTOM TEXTAREA')
          expect(page).to have_content('10 CUSTOM NUMERIC')
          expect(page).to have_content('$30.00 CUSTOM CURRENCY')
        end

        visit event_path(event)

        # expect(page).to still display the post-event format and not the form
        expect(page).to have_selector("#gender-graph")
        expect(page).to have_selector("#ethnicity-graph")
        expect(page).to have_selector("#age-graph")

        click_js_link 'Edit event data'

        fill_in 'Summary', with: 'Edited summary content'
        fill_in 'Impressions', with: '3333'
        fill_in 'Interactions', with: '222222'
        fill_in 'Samples', with: '4444444'

        click_button "Save"

        within ".box_metrics" do
          expect(page).to have_content('3,333')
          expect(page).to have_content('222,222')
          expect(page).to have_content('4,444,444')
        end

        expect(page).to have_content('Edited summary content')

        # Submit the event
        visit event_path(event)
        click_link 'submit'
        expect(page).to have_content('Your post event report has been submitted for approval')
      end

      scenario "should allow 0 for not required percentage fields" do
        kpi = FactoryGirl.create(:kpi, kpi_type: 'percentage',
          kpis_segments: [ FactoryGirl.create(:kpis_segment, text: 'Male'),
                           FactoryGirl.create(:kpis_segment, text: 'Female') ] )

        campaign.add_kpi kpi

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign, place: place )

        visit event_path(event)

        click_js_button "Save"

        expect(page).to have_no_content("The sum of the segments should be 100%")
      end

      scenario "should NOT allow 0 or less for the sum of required percentage fields" do
        kpi = FactoryGirl.create(:kpi, kpi_type: 'percentage',
          kpis_segments: [ FactoryGirl.create(:kpis_segment, text: 'Male'),
                           FactoryGirl.create(:kpis_segment, text: 'Female') ] )

        field = campaign.add_kpi(kpi)
        field.required = true
        field.save

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign, place: place )

        visit event_path(event)

        click_js_button "Save"

        expect(find_field('Male')).to have_error('This field is required.')
        expect(find_field('Female')).to have_error('This field is required.')

        fill_in('Male', with: 35)
        fill_in('Female', with: 30)
        expect(page).to have_content("Field should sum 100%")

        within "#event-results-form" do
          expect(page).to have_content('65%')
        end

        fill_in('Female', with: 65)

        click_js_button "Save"

        expect(page).to have_no_content("Field should sum 100%")
      end

      scenario "should display correct messages for range validations" do
        FactoryGirl.create(:form_field,
          name: 'Numeric Min Max',
          type: 'FormField::Number',
          settings: {'range_format' => 'value', 'range_min' => '5', 'range_max' => '20'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Numeric Max',
          type: 'FormField::Number',
          settings: {'range_format' => 'value', 'range_min' => '', 'range_max' => '20'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Price Min Max',
          type: 'FormField::Currency',
          settings: {'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Price Min',
          type: 'FormField::Currency',
          settings: {'range_format' => 'digits', 'range_min' => '2', 'range_max' => ''},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Text Min Max',
          type: 'FormField::Text',
          settings: {'range_format' => 'characters', 'range_min' => '1', 'range_max' => '10'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Text Max',
          type: 'FormField::Text',
          settings: {'range_format' => 'characters', 'range_min' => '', 'range_max' => '10'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Text Area Min Max',
          type: 'FormField::TextArea',
          settings: {'range_format' => 'words', 'range_min' => '3', 'range_max' => '5'},
          fieldable: campaign,
          required: false)

        FactoryGirl.create(:form_field,
          name: 'Text Area Min',
          type: 'FormField::TextArea',
          settings: {'range_format' => 'words', 'range_min' => '3', 'range_max' => ''},
          fieldable: campaign,
          required: false)

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign, place: place )

        visit event_path(event)

        fill_in('Numeric Min Max', with: 35)
        fill_in('Numeric Max', with: 35)
        fill_in('Price Min Max', with: 1)
        fill_in('Price Min', with: 1)
        fill_in('Text Min Max', with: 'This field has more than 10 characters')
        fill_in('Text Max', with: 'This field has more than 10 characters')
        fill_in('Text Area Min Max', with: 'Incorrect text')
        fill_in('Text Area Min', with: 'Incorrect text')

        click_js_button "Save"

        expect(find_field('Numeric Min Max')).to have_error('should be between 5 and 20')
        expect(find_field('Numeric Max')).to have_error('should be smaller than 20')
        expect(find_field('Price Min Max')).to have_error('should have at least 2 but no more than 4 digits')
        expect(find_field('Price Min')).to have_error('should have at least 2 digits')
        expect(find_field('Text Min Max')).to have_error('should have at least 1 but no more than 10 characters')
        expect(find_field('Text Max')).to have_error('should have no more than 10 characters')
        expect(find_field('Text Area Min Max')).to have_error('should have at least 3 but no more than 5 words')
        expect(find_field('Text Area Min')).to have_error('should have at least 3 words')

        fill_in('Numeric Min Max', with: 10)
        fill_in('Numeric Max', with: 10)
        fill_in('Price Min Max', with: 1000)
        fill_in('Price Min', with: 1000)
        fill_in('Text Min Max', with: 'Correct')
        fill_in('Text Max', with: 'Correct')
        fill_in('Text Area Min Max', with: 'This is a correct text')
        fill_in('Text Area Min', with: 'This is a correct text')

        click_js_button "Save"

        expect(page).not_to have_text('should be betwee 5 and 20')
        expect(page).not_to have_text('should be smaller than 20')
        expect(page).not_to have_text('should have at least 2 but no more than 4 digits')
        expect(page).not_to have_text('should have at least 2 digits')
        expect(page).not_to have_text('should have at least 1 but no more than 10 characters')
        expect(page).not_to have_text('should have no more than 10 characters')
        expect(page).not_to have_text('should have at least 3 but no more than 5 words')
        expect(page).not_to have_text('should have at least 3 words')
      end
  end

  feature "non admin user", js: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user with permissions to fill post event data" do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [
        [:index, 'Event'], [:view_list, 'Event'], [:show, 'Event'],
        [:view_unsubmitted_data, 'Event'], [:edit_unsubmitted_data, 'Event'],
        [:submit, 'Event']] }
    end
  end

  feature "admin user", js: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user with permissions to fill post event data"
  end
end