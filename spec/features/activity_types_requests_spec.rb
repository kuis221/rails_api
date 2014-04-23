require 'spec_helper'

feature "ActivityTypes", js: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  feature "/activity_types", search: true  do
    scenario "GET index should display a table with the day_parts" do
      activity_types = [
        FactoryGirl.create(:activity_type, company: @company, name: 'Morningns', description: 'From 8 to 11am', active: true),
        FactoryGirl.create(:activity_type, company: @company, name: 'Afternoons', description: 'From 1 to 6pm', active: true)
      ]
      Sunspot.commit
      visit activity_types_path

      within("ul#activity_types-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Afternoons')
          expect(page).to have_content('From 1 to 6pm')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Morningns')
          expect(page).to have_content('From 8 to 11am')
        end
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

    scenario "should allow user to deactivate activity types" do
      FactoryGirl.create(:activity_type, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: @company)
      Sunspot.commit
      visit activity_types_path

      expect(page).to have_content('A Vinos ticos')
      within("ul#activity_types-list li:nth-child(1)") do
        click_js_link('Deactivate')
      end
      confirm_prompt 'Are you sure you want to deactivate this activity type?'

      expect(page).to have_no_content('A Vinos ticos')
    end

    scenario "should allow user to activate activity type" do
      FactoryGirl.create(:activity_type, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: false, company: @company)
      Sunspot.commit
      visit activity_types_path

      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      expect(page).to have_content('A Vinos ticos')
      within("ul#activity_types-list li:nth-child(1)") do
        click_js_link('Activate')
      end
      expect(page).to have_no_content('A Vinos ticos')
    end

    scenario "should allow user to edit an activity type" do
      FactoryGirl.create(:activity_type, name: 'A test activity type', description: 'Algunos vinos de Costa Rica', company: @company)
      Sunspot.commit
      visit activity_types_path

      expect(page).to have_content('A test activity type')
      within("ul#activity_types-list li:nth-child(1)") do
        click_js_link('Edit')
      end

      within visible_modal do
        fill_in 'Name', with: 'Drink feature'
        fill_in 'Description', with: 'A description for drink feature type'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within("ul#activity_types-list li:nth-child(1)") do
        expect(page).to have_no_content('A test activity type')
        expect(page).to have_content('Drink feature')
        expect(page).to have_content('A description for drink feature type')
      end
    end
  end

  feature "activity type details view" do
    scenario "should allow user to edit an activity type" do
      activity_type = FactoryGirl.create(:activity_type, name: 'A test activity type', description: 'Algunos vinos de Costa Rica', company: @company)
      Sunspot.commit
      visit activity_type_path(activity_type)

      expect(page).to have_selector('h2', text: 'A test activity type')
      find('.links-data').click_js_link('Edit')

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

  feature "report builder" do
    let (:activity_type) { FactoryGirl.create(:activity_type, name: 'Drink Menu', company: @company) }
    scenario "user can add paragraph fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      text_area_field.drag_to form_builder

      expect(form_builder).to have_form_field('Paragraph')

      within form_field_settings_for 'Paragraph' do
        fill_in 'Field label', with: 'My Text Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Text Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Text Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::TextArea'

      within form_field_settings_for 'My Text Field' do
        expect(find_field('Field label').value).to eql 'My Text Field'
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add single line text fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      text_field.drag_to form_builder

      expect(form_builder).to have_form_field('Single line text')

      within form_field_settings_for 'Single line text' do
        fill_in 'Field label', with: 'My Text Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Text Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Text Field'
      expect(field.ordering).to eql 0
      expect(field.required).to be_true
      expect(field.type).to eql 'FormField::Text'

      within form_field_settings_for 'My Text Field' do
        expect(find_field('Field label').value).to eql 'My Text Field'
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add numeric fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      number_field.drag_to form_builder

      expect(form_builder).to have_form_field('Number')

      within form_field_settings_for 'Number' do
        fill_in 'Field label', with: 'My Numeric Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Numeric Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Numeric Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Number'

      within form_field_settings_for 'My Numeric Field' do
        expect(find_field('Field label').value).to eql 'My Numeric Field'
        expect(find_field('Required')['checked']).to be_true
      end
    end


    scenario "user can add currency fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      price_field.drag_to form_builder

      expect(form_builder).to have_form_field('Price')

      within form_field_settings_for 'Price' do
        fill_in 'Field label', with: 'My Price Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Price Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Price Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Currency'

      within form_field_settings_for 'My Price Field' do
        expect(find_field('Field label').value).to eql 'My Price Field'
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add radio fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      radio_field.drag_to form_builder

      expect(form_builder).to have_form_field('Multiple Choice',
          with_options: ['Option 1']
        )

      within form_field_settings_for 'Multiple Choice' do
        fill_in 'Field label', with: 'My Radio Field'
        fill_in 'option[0][name]', with: 'First Option'
        click_js_link 'Add option after this' # Create another option
        fill_in 'option[1][name]', with: 'Second Option'
      end

      expect(form_builder).to have_form_field('My Radio Field',
          with_options: ['First Option', 'Second Option']
        )

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to change(FormField, :count).by(1)
      }.to change(FormFieldOption, :count).by(2)
      field = FormField.last
      expect(field.name).to eql 'My Radio Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Radio'
      expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
      expect(field.options.map(&:ordering)).to eql [0, 1]

      # Remove fields
      expect(form_builder).to have_form_field('My Radio Field',
          with_options: ['First Option', 'Second Option']
        )

      within form_field_settings_for 'My Radio Field' do
        # Remove the second option (the first one doesn't have the link)
        within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
        expect(page).to have_no_content('Second Option')
      end

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to_not change(FormField, :count)
      }.to change(FormFieldOption, :count).by(-1)
    end

    scenario "user can add checkbox fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      checkbox_field.drag_to form_builder

      expect(form_builder).to have_form_field('Checkboxes',
          with_options: ['Option 1']
        )

      within form_field_settings_for 'Checkboxes' do
        fill_in 'Field label', with: 'My Checkbox Field'
        fill_in 'option[0][name]', with: 'First Option'
        click_js_link 'Add option after this' # Create another option
        fill_in 'option[1][name]', with: 'Second Option'
      end

      expect(form_builder).to have_form_field('My Checkbox Field',
          with_options: ['First Option', 'Second Option']
        )

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to change(FormField, :count).by(1)
      }.to change(FormFieldOption, :count).by(2)
      field = FormField.last
      expect(field.name).to eql 'My Checkbox Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Checkbox'
      expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
      expect(field.options.map(&:ordering)).to eql [0, 1]

      # Remove fields
      expect(form_builder).to have_form_field('My Checkbox Field',
          with_options: ['First Option', 'Second Option']
        )

      within form_field_settings_for 'My Checkbox Field' do
        # Remove the second option (the first one doesn't have the link)
        within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
        expect(page).to have_no_content('Second Option')
      end

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to_not change(FormField, :count)
      }.to change(FormFieldOption, :count).by(-1)
    end

    scenario "user can add dropdown fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      dropdown_field.drag_to form_builder

      expect(form_builder).to have_form_field('Dropdown',
          with_options: ['Option 1']
        )

      within form_field_settings_for 'Dropdown' do
        fill_in 'Field label', with: 'My Dropdown Field'
        fill_in 'option[0][name]', with: 'First Option'
        click_js_link 'Add option after this' # Create another option
        fill_in 'option[1][name]', with: 'Second Option'
      end

      expect(form_builder).to have_form_field('My Dropdown Field',
          with_options: ['First Option', 'Second Option']
        )

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to change(FormField, :count).by(1)
      }.to change(FormFieldOption, :count).by(2)
      field = FormField.last
      expect(field.name).to eql 'My Dropdown Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Dropdown'
      expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
      expect(field.options.map(&:ordering)).to eql [0, 1]

      # Remove fields
      expect(form_builder).to have_form_field('My Dropdown Field',
          with_options: ['First Option', 'Second Option']
        )

      within form_field_settings_for 'My Dropdown Field' do
        # Remove the second option (the first one doesn't have the link)
        within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
        expect(page).to have_no_content('Second Option')
      end

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to_not change(FormField, :count)
      }.to change(FormFieldOption, :count).by(-1)
    end

    scenario "user can add date fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      date_field.drag_to form_builder

      expect(form_builder).to have_form_field('Date')

      within form_field_settings_for 'Date' do
        fill_in 'Field label', with: 'My Date Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Date Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Date Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Date'

      within form_field_settings_for 'My Date Field' do
        expect(find_field('Field label').value).to eql 'My Date Field'
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add time fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      time_field.drag_to form_builder

      expect(form_builder).to have_form_field('Time')

      within form_field_settings_for 'Time' do
        fill_in 'Field label', with: 'My Time Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Time Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Time Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Time'

      within form_field_settings_for 'My Time Field' do
        expect(find_field('Field label').value).to eql 'My Time Field'
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add brand fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      brand_field.drag_to form_builder

      expect(form_builder).to have_form_field('Brand')

      within form_field_settings_for 'Brand' do
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('Brand')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'Brand'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Brand'

      within form_field_settings_for 'Brand' do
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add marque fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      marque_field.drag_to form_builder

      expect(form_builder).to have_form_field('Marque')

      within form_field_settings_for 'Marque' do
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('Marque')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'Marque'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Marque'

      within form_field_settings_for 'Marque' do
        expect(find_field('Required')['checked']).to be_true
      end
    end

    scenario "user can add photo fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      photo_field.drag_to form_builder

      expect(form_builder).to have_form_field('Photo')

      within form_field_settings_for 'Photo' do
        fill_in 'Field label', with: 'My Photo Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Photo Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Photo Field'
      expect(field.ordering).to eql 0
      expect(field.required).to be_true
      expect(field.type).to eql 'FormField::Photo'
    end

    scenario "user can add attachement fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      attachment_field.drag_to form_builder

      expect(form_builder).to have_form_field('Attachment')

      within form_field_settings_for 'Attachment' do
        fill_in 'Field label', with: 'My Attachment Field'
        unicheck('Required')
      end

      expect(form_builder).to have_form_field('My Attachment Field')

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)
      field = FormField.last
      expect(field.name).to eql 'My Attachment Field'
      expect(field.ordering).to eql 0
      expect(field.required).to be_true
      expect(field.type).to eql 'FormField::Attachment'
    end

    scenario "user can add percentage fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      percentage_field.drag_to form_builder

      expect(form_builder).to have_form_field('Percent',
          with_options: ['Option 1']
        )

      within form_field_settings_for 'Percent' do
        fill_in 'Field label', with: 'My Percent Field'
        fill_in 'option[0][name]', with: 'First Option'
        click_js_link 'Add option after this' # Create another option
        fill_in 'option[1][name]', with: 'Second Option'
      end

      expect(form_builder).to have_form_field('My Percent Field',
          with_options: ['First Option', 'Second Option']
        )

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to change(FormField, :count).by(1)
      }.to change(FormFieldOption, :count).by(2)
      field = FormField.last
      expect(field.name).to eql 'My Percent Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Percentage'
      expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
      expect(field.options.map(&:ordering)).to eql [0, 1]

      # Remove fields
      expect(form_builder).to have_form_field('My Percent Field',
        with_options: ['First Option', 'Second Option']
      )

      within form_field_settings_for 'My Percent Field' do
        # Remove the second option (the first one doesn't have the link)
        within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
        expect(page).to have_no_content('Second Option')
      end

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to_not change(FormField, :count)
      }.to change(FormFieldOption, :count).by(-1)
    end

    scenario "user can add summation fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      summation_field.drag_to form_builder

      expect(form_builder).to have_form_field('Summation',
          with_options: ['Option 1', 'Option 2']
        )

      within form_field_settings_for 'Summation' do
        fill_in 'Field label', with: 'My Summation Field'
        fill_in 'option[0][name]', with: 'First Option'
        within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' } # Create another option
        fill_in 'option[1][name]', with: 'Second Option'
      end

      expect(form_builder).to have_form_field('My Summation Field',
          with_options: ['First Option', 'Second Option']
        )

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to change(FormField, :count).by(1)
      }.to change(FormFieldOption, :count).by(3)
      field = FormField.last
      expect(field.name).to eql 'My Summation Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::Summation'
      expect(field.options.map(&:name)).to eql ["First Option", "Second Option", "Option 2"]
      expect(field.options.map(&:ordering)).to eql [0, 1, 2]

      # Remove fields
      expect(form_builder).to have_form_field('My Summation Field',
        with_options: ['First Option', 'Second Option']
      )

      within form_field_settings_for 'My Summation Field' do
        # Remove the second option (the first one doesn't have the link)
        within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
        expect(page).to have_no_content('Second Option')
      end

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to_not change(FormField, :count)
      }.to change(FormFieldOption, :count).by(-1)
    end

    scenario "user can add likert scale fields to form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      likert_scale_field.drag_to form_builder

      expect(form_builder).to have_form_field('Likert scale',
          with_options: ['Strongly Disagree', 'Disagree', 'Agree', 'Strongly Agree']
        )

      within form_field_settings_for 'Likert scale' do
        fill_in 'Field label', with: 'My Likert scale Field'

        within '.field-options[data-type="statement"]' do
          fill_in 'statement[0][name]', with: 'First Statement'
          within('.field-option', match: :first){ click_js_link 'Add option after this' } # Create another option
          fill_in 'statement[1][name]', with: 'Second Statement'
        end

        within '.field-options[data-type="option"]' do
          fill_in 'option[0][name]', with: 'First Option'
          within('.field-option', match: :first){ click_js_link 'Add option after this' } # Create another option
          fill_in 'option[1][name]', with: 'Second Option'
        end
      end

      expect(form_builder).to have_form_field('My Likert scale Field',
          with_options: ['First Option', 'Second Option']
        )

      # Close the field settings form
      form_builder.trigger 'click'
      expect(page).to have_no_selector('.field-attributes-panel')

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to change(FormField, :count).by(1)
      }.to change(FormFieldOption, :count).by(9)
      field = FormField.last
      expect(field.name).to eql 'My Likert scale Field'
      expect(field.ordering).to eql 0
      expect(field.type).to eql 'FormField::LikertScale'
      expect(field.options.order('ordering ASC').map(&:name)).to eql ['First Option', 'Second Option', 'Disagree', 'Agree', 'Strongly Agree']
      expect(field.options.map(&:ordering)).to eql [0, 1, 2, 3, 4]
      expect(field.statements.map(&:name)).to eql ['First Statement', 'Second Statement', 'Statement 2', 'Statement 3']
      expect(field.statements.map(&:ordering)).to eql [0, 1, 2, 3]

      # Remove fields
      expect(form_builder).to have_form_field('My Likert scale Field',
        with_options: ['First Option', 'Second Option', 'Disagree', 'Agree', 'Strongly Agree']
      )

      within form_field_settings_for 'My Likert scale Field' do
        # Remove the second option (the first one doesn't have the link)
        within '.field-options[data-type="option"]' do
          within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }
          expect(page).to have_no_content('Second Option')
        end
        within '.field-options[data-type="statement"]' do
          within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }
          expect(page).to have_no_content('Second Statement')
        end
      end

      # Save the form
      expect {
        expect {
          click_js_button 'Save'
          wait_for_ajax
        }.to_not change(FormField, :count)
      }.to change(FormFieldOption, :count).by(-2)
    end

    scenario "user can remove a field from the form that was just added" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      text_field.drag_to form_builder

      expect(form_builder).to have_form_field('Single line text')

      form_field_settings_for 'Single line text'
      within form_builder.find('.field.selected') do
        click_js_link 'Remove'
      end

      confirm_prompt "Do you really want to delete this field?"

      expect(form_builder).to_not have_form_field('Single line text')

      # Save the form, should not create any field
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to_not change(FormField, :count)
    end

    scenario "user can remove an existing field from the form" do
      visit activity_type_path activity_type
      expect(page).to have_selector('h2', text: 'Drink Menu')
      text_field.drag_to form_builder

      expect(form_builder).to have_form_field('Single line text')
      # Save the form
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(1)

      visit activity_type_path activity_type

      expect(form_builder).to have_form_field('Single line text')

      form_field_settings_for 'Single line text'
      within form_builder.find('.field.selected') do
        click_js_link 'Remove'
      end

      confirm_prompt "Deleting this field will also delete all the associated data"

      expect(form_builder).to_not have_form_field('Single line text')

      # Save the form, should not create any field
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to change(FormField, :count).by(-1)
    end
  end

  def text_area_field
    find('.fields-wrapper .field', text: 'Paragraph')
  end

  def number_field
    find('.fields-wrapper .field', text: 'Number')
  end

  def price_field
    find('.fields-wrapper .field', text: 'Price')
  end

  def text_field
    find('.fields-wrapper .field', text: 'Single line text')
  end

  def dropdown_field
    find('.fields-wrapper .field', text: 'Dropdown')
  end

  def radio_field
    find('.fields-wrapper .field', text: 'Multiple Choice')
  end

  def checkbox_field
    find('.fields-wrapper .field', text: 'Checkboxes')
  end

  def date_field
    find('.fields-wrapper .field', text: 'Date')
  end

  def time_field
    find('.fields-wrapper .field', text: 'Time')
  end

  def brand_field
    find('.fields-wrapper .field', text: 'Brand')
  end

  def marque_field
    find('.fields-wrapper .field', text: 'Marque')
  end

  def percentage_field
    find('.fields-wrapper .field', text: 'Percent')
  end

  def photo_field
    find('.fields-wrapper .field', text: 'Photo')
  end

  def attachment_field
    find('.fields-wrapper .field', text: 'Attachment')
  end

  def summation_field
    find('.fields-wrapper .field', text: 'Summation')
  end

  def likert_scale_field
    find('.fields-wrapper .field', text: 'Likert scale')
  end

  def form_builder
    find('.form-fields')
  end

  def form_field_settings_for(field_name)
    form_field(field_name).trigger 'click'
    find('.field-attributes-panel')
  end

  def form_field(field_name)
    field = nil
    form_builder.all('.field').each do |wrapper|
      field = wrapper if wrapper.all('label.control-label', :text => field_name).count > 0
    end
    raise "Field #{field_name} not found" if field.nil?
    field
  end
end
