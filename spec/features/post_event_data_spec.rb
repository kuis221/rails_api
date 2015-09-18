require 'rails_helper'

feature 'Post Event Data' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { create(:event, campaign: campaign, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user with permissions to fill post event data' do
    scenario 'should allow the user to fill the event data' do
      Kpi.create_global_kpis
      event = create(:event,
                     start_date: Date.yesterday.to_s(:slashes),
                     end_date: Date.yesterday.to_s(:slashes),
                     campaign: campaign,
                     place: place,
                     company: company)
      campaign.assign_all_global_kpis

      campaign.add_kpi create(:kpi, name: 'Integer field', kpi_type: 'number', capture_mechanism: 'integer')
      campaign.add_kpi create(:kpi, name: 'Decimal field', kpi_type: 'number', capture_mechanism: 'decimal')
      campaign.add_kpi create(:kpi, name: 'Currency field', kpi_type: 'number', capture_mechanism: 'currency')
      campaign.add_kpi create(:kpi, name: 'Radio field', kpi_type: 'count', capture_mechanism: 'radio', kpis_segments: [
        create(:kpis_segment, text: 'Radio Option 1'),
        create(:kpis_segment, text: 'Radio Option 2')
      ])

      campaign.add_kpi create(:kpi, name: 'Checkbox field', kpi_type: 'count', capture_mechanism: 'checkbox', kpis_segments: [
        create(:kpis_segment, text: 'Checkbox Option 1'),
        create(:kpis_segment, text: 'Checkbox Option 2'),
        create(:kpis_segment, text: 'Checkbox Option 3')
      ])

      brand = create(:brand, name: 'Cacique', company_id: company.to_param)
      create(:marque, name: 'Marque #1 for Cacique', brand: brand)
      create(:marque, name: 'Marque #2 for Cacique', brand: brand)
      campaign.brands << brand

      venue = create(:venue,
                     company: company,
                     place: create(:place,
                                   name: 'Bar Los Profesionales', street_number: '198',
                                   route: '3rd Ave', city: 'San José'))
      Sunspot.commit
      company_user.places << venue.place

      # Create some custom fields of different types
      create(:form_field,
             name: 'Custom Place',
             type: 'FormField::Place',
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Single Text',
             type: 'FormField::Text',
             settings: { 'range_format' => 'characters', 'range_min' => '5', 'range_max' => '20' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom TextArea',
             type: 'FormField::TextArea',
             settings: { 'range_format' => 'words', 'range_min' => '2', 'range_max' => '4' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Numeric',
             type: 'FormField::Number',
             settings: { 'range_format' => 'value', 'range_min' => '5', 'range_max' => '20' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Date',
             type: 'FormField::Date',
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Time',
             type: 'FormField::Time',
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Currency',
             type: 'FormField::Currency',
             settings: { 'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Summation',
             type: 'FormField::Summation',
             options: [
               create(:form_field_option, name: 'Summation Opt1'),
               create(:form_field_option, name: 'Summation Opt2')],
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Percentage',
             type: 'FormField::Percentage',
             options: [
               create(:form_field_option, name: 'Percentage Opt1', ordering: 1),
               create(:form_field_option, name: 'Percentage Opt2', ordering: 2)],
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom LikertScale',
             type: 'FormField::LikertScale',
             options: [
               create(:form_field_option, name: 'LikertScale Opt1'),
               create(:form_field_option, name: 'LikertScale Opt2')],
             statements: [
               create(:form_field_statement, name: 'LikertScale Stat1'),
               create(:form_field_statement, name: 'LikertScale Stat2')],
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Checkbox',
             type: 'FormField::Checkbox',
             options: [
               create(:form_field_option, name: 'Checkbox Opt1', ordering: 1),
               create(:form_field_option, name: 'Checkbox Opt2', ordering: 2)],
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Custom Radio',
             type: 'FormField::Radio',
             options: [
               create(:form_field_option, name: 'Radio Opt1', ordering: 1),
               create(:form_field_option, name: 'Radio Opt2', ordering: 2)],
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Brand',
             type: 'FormField::Brand',
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Marque',
             type: 'FormField::Marque',
             fieldable: campaign,
             required: false)

      visit event_path(event)

      select_from_autocomplete 'Search for a place', 'Bar Los Profesionales'

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

      unicheck 'Checkbox Option 1'
      unicheck 'Checkbox Option 2'

      # Fill in the custom (non KPI) fields
      fill_in 'Custom Single Text', with: 'Testing Single'
      fill_in 'Custom TextArea', with: 'Testing Area'
      fill_in 'Custom Numeric', with: '10'
      fill_in 'Custom Currency', with: '30'
      fill_in 'Custom Date', with: '08/13/2013'
      select_time '2:30am', from: 'Custom Time'

      fill_in 'Summation Opt1', with: '100'
      fill_in 'Summation Opt2', with: '2000'

      fill_in 'Percentage Opt1', with: '75'
      fill_in 'Percentage Opt2', with: '25'

      unicheck 'Checkbox Opt1'
      unicheck 'Checkbox Opt2'

      choose 'Radio Option 1'
      choose 'Radio Opt1'

      select_from_chosen('Cacique', from: 'Brand')
      select_from_chosen('Marque #2 for Cacique', from: 'Marque')

      click_js_button 'Save'

      # Ensure the results are displayed on the page

      expect(page).to have_content '20%'
      expect(page).to have_content '12%'
      expect(page).to have_content '13%'
      expect(page).to have_content '34%'
      expect(page).to have_content '21%'

      expect(page).to have_content '34%'
      expect(page).to have_content '66%'

      expect(page).to have_content '9%'
      expect(page).to have_content '10%'
      expect(page).to have_content '11%'
      expect(page).to have_content '12%'
      expect(page).to have_content '13%'
      expect(page).to have_content '14%'
      expect(page).to have_content '15%'
      expect(page).to have_content '16%'

      within '.form-results-box' do
        expect(page).to have_content('Integer field 99')
        expect(page).to have_content('Decimal field 99.9')
        expect(page).to have_content('Currency field $79.90')
        expect(page).to have_content('Radio field Radio Option 1')
        expect(page).to have_content('Checkbox field Checkbox Option 1 Checkbox Option 2')
        expect(page).to have_content('Custom Checkbox Checkbox Opt1 Checkbox Opt2')
        expect(page).to have_content('Custom Radio Radio Opt1')
        expect(page).to have_content('Custom Single Text Testing Single')
        expect(page).to have_content('Custom TextArea Testing Area')
        expect(page).to have_content('Custom Numeric 10')
        expect(page).to have_content('Custom Currency $30.00')
        expect(page).to have_content('Marque Marque #2 for Cacique')
        expect(page).to have_content('Brand Cacique')
        expect(page).to have_content('Custom Date TUE Aug 13, 2013')
        expect(page).to have_content('Custom Time 02:30 AM')

        expect(page).to have_content('Summation Opt1 100')
        expect(page).to have_content('Summation Opt2 2,000')
        expect(page).to have_content('TOTAL:2,100.0')
      end

      visit event_path(event)

      # expect(page).to still display the post-event format and not the form
      within '.form-results-box' do
        expect(page).to have_content('Integer field 99')
        expect(page).to have_content('Decimal field 99.9')
        expect(page).to have_content('Currency field $79.90')
      end

      click_js_link 'Edit event data'

      fill_in 'Impressions', with: '3333'
      fill_in 'Interactions', with: '222222'
      fill_in 'Samples', with: '4444444'
      fill_in 'Summation Opt1', with: '0.75'
      fill_in 'Summation Opt2', with: '0.5'

      click_js_button 'Save'

      within '.form-results-box' do
        expect(page).to have_content('3,333')
        expect(page).to have_content('222,222')
        expect(page).to have_content('4,444,444')
        expect(page).to have_content('Summation Opt1 0.75')
        expect(page).to have_content('Summation Opt2 0.5')
        expect(page).to have_content('TOTAL:1.25')
      end
    end

    scenario 'should allow 0 for not required percentage fields' do
      kpi = create(:kpi, kpi_type: 'percentage',
                         kpis_segments: [create(:kpis_segment, text: 'Male'),
                                         create(:kpis_segment, text: 'Female')])

      campaign.add_kpi kpi

      event = create(:event,
                     start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
                     campaign: campaign, place: place)

      visit event_path(event)

      click_js_button 'Save'

      expect(page).to have_no_content('The sum of the segments should be 100%')
    end

    scenario 'should NOT allow 0 or less for the sum of required percentage fields' do
      kpi = create(:kpi, kpi_type: 'percentage',
                         kpis_segments: [create(:kpis_segment, text: 'Male'),
                                         create(:kpis_segment, text: 'Female')])

      field = campaign.add_kpi(kpi)
      field.required = true
      field.save

      event = create(:event,
                     start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
                     campaign: campaign, place: place)

      visit event_path(event)

      click_js_button 'Save'

      within '#progress-error-' + field.id.to_s do
        expect(page).to have_content('This field is required.')
      end

      fill_in('Male', with: 35)
      fill_in('Female', with: 30)
      error_msg = 'Field must sum to 100%'
      expect(page).to have_content(error_msg)

      within '#event-results-form' do
        expect(page).to have_content('65%')
      end

      fill_in('Female', with: 65)

      expect(page).to_not have_content(error_msg)

      click_js_button 'Save'

      expect(page).to_not have_content(error_msg)
      expect(page).to have_content('Looks good! Your Post Event Recap is complete.')
    end

    scenario 'should display correct messages for range validations' do
      create(:form_field,
             name: 'Numeric with Min Max',
             type: 'FormField::Number',
             settings: { 'range_format' => 'value', 'range_min' => '5', 'range_max' => '20' },
             fieldable: campaign,
             required: true)

      create(:form_field,
             name: 'Numeric Max Value',
             type: 'FormField::Number',
             settings: { 'range_format' => 'value', 'range_min' => '', 'range_max' => '20' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Numeric Max Digits',
             type: 'FormField::Number',
             settings: { 'range_format' => 'digits', 'range_min' => '', 'range_max' => '2' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Price with Min Max',
             type: 'FormField::Currency',
             settings: { 'range_format' => 'digits', 'range_min' => '2', 'range_max' => '4' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Price Min Digits',
             type: 'FormField::Currency',
             settings: { 'range_format' => 'digits', 'range_min' => '2', 'range_max' => '' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Price Min Value',
             type: 'FormField::Currency',
             settings: { 'range_format' => 'value', 'range_min' => '5', 'range_max' => '' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Text with Min Max',
             type: 'FormField::Text',
             settings: { 'range_format' => 'characters', 'range_min' => '1', 'range_max' => '10' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Text Max',
             type: 'FormField::Text',
             settings: { 'range_format' => 'characters', 'range_min' => '', 'range_max' => '10' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Text Area with Min Max',
             type: 'FormField::TextArea',
             settings: { 'range_format' => 'words', 'range_min' => '3', 'range_max' => '5' },
             fieldable: campaign,
             required: false)

      create(:form_field,
             name: 'Text Area Min',
             type: 'FormField::TextArea',
             settings: { 'range_format' => 'words', 'range_min' => '3', 'range_max' => '' },
             fieldable: campaign,
             required: false)

      event = create(:event,
                     start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
                     campaign: campaign, place: place)

      visit event_path(event)

      # Ensure that validation errors are not displayed after first time form load
      expect(all('.event_results_value.error').count).to be 0

      expect(find_field('Numeric with Min Max')).to have_hint('Enter a number between 5 and 20')
      expect(find_field('Numeric Max Value')).to have_hint('Enter a number no higher than 20')
      expect(find_field('Numeric Max Digits')).to have_hint('Enter a number with no higher than 2 digits')
      expect(find_field('Price with Min Max')).to have_hint('Enter a number between 2 and 4')
      expect(find_field('Price Min Digits')).to have_hint('Enter a number with 2 digits or higher')
      expect(find_field('Price Min Value')).to have_hint('Enter a number 5 or higher')
      expect(find_field('Text with Min Max')).to have_hint('Must be between 1 and 10 characters Currently: 0 characters')
      expect(find_field('Text Max')).to have_hint('Must be no more than 10 characters Currently: 0 characters')
      expect(find_field('Text Area with Min Max')).to have_hint('Must be between 3 and 5 words Currently: 0 words')
      expect(find_field('Text Area Min')).to have_hint('Must be at least 3 words Currently: 0 words')

      fill_in('Numeric with Min Max', with: 35)
      fill_in('Numeric Max Value', with: 35)
      fill_in('Numeric Max Digits', with: 400)
      fill_in('Price with Min Max', with: 1)
      fill_in('Price Min Digits', with: 1)
      fill_in('Price Min Value', with: 3)
      fill_in('Text with Min Max', with: 'This field has more than 10 characters')
      fill_in('Text Max', with: 'This field has more than 10 characters')
      fill_in('Text Area with Min Max', with: 'Incorrect text')
      fill_in('Text Area Min', with: 'Incorrect text')

      expect(find_field('Text with Min Max')).to have_hint('Must be between 1 and 10 characters Currently: 38 characters')
      expect(find_field('Text Max')).to have_hint('Must be no more than 10 characters Currently: 38 characters')
      expect(find_field('Text Area with Min Max')).to have_hint('Must be between 3 and 5 words Currently: 2 words')
      expect(find_field('Text Area Min')).to have_hint('Must be at least 3 words Currently: 2 words')

      click_js_button 'Save'

      expect(find_field('Numeric with Min Max')).to_not have_css('.valid')
      expect(find_field('Numeric with Min Max')).to_not have_css('.valid')
      expect(find_field('Numeric Max Value')).to_not have_css('.valid')
      expect(find_field('Numeric Max Digits')).to_not have_css('.valid')
      expect(find_field('Price with Min Max')).to_not have_css('.valid')
      expect(find_field('Price Min Digits')).to_not have_css('.valid')
      expect(find_field('Price Min Value')).to_not have_css('.valid')
      expect(find_field('Text with Min Max')).to_not have_css('.valid')
      expect(find_field('Text Max')).to_not have_css('.valid')
      expect(find_field('Text Area with Min Max')).to_not have_css('.valid')
      expect(find_field('Text Area Min')).to_not have_css('.valid')

      fill_in('Numeric with Min Max', with: 10)
      fill_in('Numeric Max Value', with: 10)
      fill_in('Numeric Max Digits', with: 15)
      fill_in('Price with Min Max', with: 1000)
      fill_in('Price Min Digits', with: 1000)
      fill_in('Price Min Value', with: 100)
      fill_in('Text with Min Max', with: 'Correct')
      fill_in('Text Max', with: 'Correct')
      fill_in('Text Area with Min Max', with: 'This is a correct text')
      fill_in('Text Area Min', with: 'This is a correct text')

      click_js_button 'Save'

      expect(page).to have_link('Edit event data')
      expect(page).to_not have_button('Save')
    end

    scenario 'should display message for likert scale radio validation' do
      field = create(:form_field,
                     name: 'Custom LikertScale',
                     type: 'FormField::LikertScale',
                     options: [
                       create(:form_field_option, name: 'LikertScale Opt1'),
                       create(:form_field_option, name: 'LikertScale Opt2')],
                     statements: [
                       create(:form_field_statement, name: 'LikertScale Stat1'),
                       create(:form_field_statement, name: 'LikertScale Stat2')],
                     fieldable: campaign,
                     required: true)
      event = create(:event,
                     start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
                     campaign: campaign, place: place)

      visit event_path(event)

      click_js_button 'Save'

      expect(page).to have_content('This field is required.')

      radio = find("#event_results_attributes_0_value_#{ field.statements[0].id }_#{ field.options[0].id }")
      radio.trigger('click')

      click_js_button 'Save'

      expect(page).to have_content('This field is required.')

      radio = find("#event_results_attributes_0_value_#{ field.statements[1].id }_#{ field.options[1].id }")
      radio.trigger('click')

      click_js_button 'Save'

      expect(page).to_not have_content('This field is required.')
    end

    scenario 'should display message for likert scale checkbox validation' do
      field = create(:form_field,
                     name: 'Custom LikertScale',
                     type: 'FormField::LikertScale',
                     options: [
                       create(:form_field_option, name: 'LikertScale Opt1'),
                       create(:form_field_option, name: 'LikertScale Opt2')],
                     statements: [
                       create(:form_field_statement, name: 'LikertScale Stat1'),
                       create(:form_field_statement, name: 'LikertScale Stat2')],
                     fieldable: campaign,
                     required: true,
                     multiple: true)
      event = create(:event,
                     start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
                     campaign: campaign, place: place)

      visit event_path(event)

      click_js_button 'Save'

      expect(page).to have_content('This field is required.')

      checkbox = find("#event_results_attributes_0_value_#{ field.statements[0].id }_#{ field.options[0].id }")
      checkbox.trigger('click')

      click_js_button 'Save'

      expect(page).to have_content('This field is required.')

      checkbox = find("#event_results_attributes_0_value_#{ field.statements[0].id }_#{ field.options[1].id }")
      checkbox.trigger('click')

      click_js_button 'Save'

      expect(page).to have_content('This field is required.')

      checkbox = find("#event_results_attributes_0_value_#{ field.statements[1].id }_#{ field.options[1].id }")
      checkbox.trigger('click')

      click_js_button 'Save'

      expect(page).to_not have_content('This field is required.')
    end

  end

  feature 'non admin user', js: true do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user with permissions to fill post event data' do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) do
        [
          [:index, 'Event'], [:view_list, 'Event'], [:show, 'Event'],
          [:view_unsubmitted_data, 'Event'], [:edit_unsubmitted_data, 'Event'],
          [:submit, 'Event']]
      end
    end
  end
end
