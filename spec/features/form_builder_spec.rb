require 'spec_helper'


RSpec.shared_examples "a fieldable element" do
  let(:fieldable_path) { url_for(fieldable, only_path: true) }

  scenario "user can add a field to the form by clicking on it" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    text_field.click
    expect(page).to have_content('Adding new Single line text field at the bottom...')

    expect(form_builder).to have_form_field('Single line text')

    # Save the form
    expect {
      click_js_button 'Save'
      wait_for_ajax
    }.to change(FormField, :count).by(1)
    field = FormField.last
    expect(field.type).to eql 'FormField::Text'
  end

  scenario "user can add paragraph fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::TextArea'

    within form_field_settings_for 'My Text Field' do
      expect(find_field('Field label').value).to eql 'My Text Field'
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add single line text fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.required).to be_true
    expect(field.type).to eql 'FormField::Text'

    within form_field_settings_for 'My Text Field' do
      expect(find_field('Field label').value).to eql 'My Text Field'
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add numeric fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Number'

    within form_field_settings_for 'My Numeric Field' do
      expect(find_field('Field label').value).to eql 'My Numeric Field'
      expect(find_field('Required')['checked']).to be_true
    end
  end


  scenario "user can add currency fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Currency'

    within form_field_settings_for 'My Price Field' do
      expect(find_field('Field label').value).to eql 'My Price Field'
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add/delete radio fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Radio'
    expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
    expect(field.options.map(&:ordering)).to eql [0, 1]

    # Remove fields
    expect(form_builder).to have_form_field('My Radio Field',
        with_options: ['First Option', 'Second Option']
      )

    within form_field_settings_for 'My Radio Field' do
      # Remove the second option (the first one doesn't have the link)
      within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Removing this option will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"

    within form_field_settings_for 'My Radio Field' do
      expect(page).to have_no_content('Second Option')
    end

    within form_field_settings_for 'My Radio Field' do
      # Remove the second option (the first one doesn't have the link)
      within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Are you sure you want to remove this option?"

    within form_field_settings_for 'My Radio Field' do
      expect(page).to have_no_content('Option 3')
    end

    # Save the form
    expect {
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to_not change(FormField, :count)
    }.to change(FormFieldOption, :count).by(-1)
  end

  scenario "user can add/delete checkbox fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Checkbox'
    expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
    expect(field.options.map(&:ordering)).to eql [0, 1]

    # Remove fields
    expect(form_builder).to have_form_field('My Checkbox Field',
        with_options: ['First Option', 'Second Option']
      )

    within form_field_settings_for 'My Checkbox Field' do
      # Remove the second option (the first one doesn't have the link)
      within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
    end
    confirm_prompt "Removing this option will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"
    within form_field_settings_for 'My Checkbox Field' do
      expect(page).to have_no_content('Second Option')
    end

    within form_field_settings_for 'My Checkbox Field' do
      within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Are you sure you want to remove this option?"

    within form_field_settings_for 'My Checkbox Field' do
      expect(page).to have_no_content('Option 3')
    end

    # Save the form
    expect {
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to_not change(FormField, :count)
    }.to change(FormFieldOption, :count).by(-1)
  end

  scenario "user can add/delete dropdown fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Dropdown'
    expect(field.options.map(&:name)).to eql ['First Option', 'Second Option']
    expect(field.options.map(&:ordering)).to eql [0, 1]

    # Remove fields
    expect(form_builder).to have_form_field('My Dropdown Field',
        with_options: ['First Option', 'Second Option']
      )

    within form_field_settings_for 'My Dropdown Field' do
      # Remove the second option (the first one doesn't have the link)
      within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Removing this option will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"

    within form_field_settings_for 'My Dropdown Field' do
      expect(page).to have_no_content('Second Option')
    end

    within form_field_settings_for 'My Dropdown Field' do
      within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Are you sure you want to remove this option?"

    within form_field_settings_for 'My Dropdown Field' do
      expect(page).to have_no_content('Option 3')
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
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Date'

    within form_field_settings_for 'My Date Field' do
      expect(find_field('Field label').value).to eql 'My Date Field'
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add time fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Time'

    within form_field_settings_for 'My Time Field' do
      expect(find_field('Field label').value).to eql 'My Time Field'
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add brand fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Brand'

    within form_field_settings_for 'Brand' do
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add section fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    section_field.drag_to form_builder

    expect(form_builder).to have_selector('h3', text: 'Section')

    within form_field_settings_for form_section('Section') do
      fill_in 'Description', with: 'This is the section description'
    end

    # Close the field settings form
    form_builder.trigger 'click'
    expect(page).to have_no_selector('.field-attributes-panel')

    # Save the form
    expect {
      click_js_button 'Save'
      wait_for_ajax
    }.to change(FormField, :count).by(1)
    field = FormField.last
    expect(field.name).to eql 'Section'
    expect(field.settings['description']).to eql 'This is the section description'
    expect(field.type).to eql 'FormField::Section'

    within form_field_settings_for form_section('Section') do
      expect(find_field('Description').value).to eql 'This is the section description'
    end
  end

  scenario "user can add marque fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Marque'

    within form_field_settings_for 'Marque' do
      expect(find_field('Required')['checked']).to be_true
    end
  end

  scenario "user can add photo fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.required).to be_true
    expect(field.type).to eql 'FormField::Photo'
  end

  scenario "user can add attachement fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.required).to be_true
    expect(field.type).to eql 'FormField::Attachment'
  end

  scenario "user can add/delete percentage fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    percentage_field.drag_to form_builder

    expect(form_builder).to have_form_field('Percent',
        with_options: ['Option 1', 'Option 2', 'Option 3']
      )

    within form_field_settings_for 'Percent' do
      fill_in 'Field label', with: 'My Percent Field'
      fill_in 'option[0][name]', with: 'First Option'
      within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' } # Create another option
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
    }.to change(FormFieldOption, :count).by(4)
    field = FormField.last
    expect(field.name).to eql 'My Percent Field'
    expect(field.type).to eql 'FormField::Percentage'
    expect(field.options.map(&:name)).to eql ['First Option', 'Second Option','Option 2', 'Option 3']
    expect(field.options.map(&:ordering)).to eql [0, 1,2,3]

    # Remove fields
    expect(form_builder).to have_form_field('My Percent Field',
      with_options: ['First Option', 'Second Option']
    )

    within form_field_settings_for 'My Percent Field' do
      # Remove the second option (the first one doesn't have the link)
      within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
    end
    confirm_prompt "Removing this option will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"

    within form_field_settings_for 'My Percent Field' do
      expect(page).to have_no_content('Second Option')
      within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }

    end

    confirm_prompt "Are you sure you want to remove this option?"

    within form_field_settings_for 'My Percent Field' do
      expect(page).to have_no_content('Option 3')
    end

    # Save the form
    expect {
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to_not change(FormField, :count)
    }.to change(FormFieldOption, :count).by(-1)
  end

  scenario "user can add/delete summation fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
    expect(field.type).to eql 'FormField::Summation'
    expect(field.options.map(&:name)).to eql ["First Option", "Second Option", "Option 2"]
    expect(field.options.map(&:ordering)).to eql [0, 1, 2]

    # Remove fields
    expect(form_builder).to have_form_field('My Summation Field',
      with_options: ['First Option', 'Second Option']
    )

    within form_field_settings_for 'My Summation Field' do
      # Remove the second option (the first one doesn't have the link)
      within('.field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-option:nth-child(2)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Removing this option will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"

    within form_field_settings_for 'My Summation Field' do
      expect(page).to have_no_content('Second Option')
    end

    within form_field_settings_for 'My Summation Field' do
      within('.field-option:nth-child(3)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Are you sure you want to remove this option?"
    within form_field_settings_for 'My Summation Field' do
      expect(page).to have_no_content('Option 3')
    end

    # Save the form
    expect {
      expect {
        click_js_button 'Save'
        wait_for_ajax
      }.to_not change(FormField, :count)
    }.to change(FormFieldOption, :count).by(-1)
  end

  scenario "user can add/delete likert scale fields to form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
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
      within('.field-options[data-type="option"] .field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-options[data-type="option"] .field-option:nth-child(4)') { click_js_link 'Remove this option' }
    end

    confirm_prompt "Removing this option will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"

    within form_field_settings_for 'My Likert scale Field' do
      within('.field-options[data-type="option"]') {expect(page).to have_no_content('Second Option')}
    end
    within form_field_settings_for 'My Likert scale Field' do
      within('.field-options[data-type="option"] .field-option:nth-child(3)'){ click_js_link 'Remove this option' }
    end

    confirm_prompt "Are you sure you want to remove this option?"

    within form_field_settings_for 'My Likert scale Field' do
      expect(page).to have_no_content('Option 3')
    end

    within form_field_settings_for 'My Likert scale Field' do
      # Remove the second statement (the first one doesn't have the link)
      within('.field-options[data-type="statement"] .field-option:nth-child(2)'){ click_js_link 'Add option after this' }
      within('.field-options[data-type="statement"] .field-option:nth-child(4)') { click_js_link 'Remove this option' }
    end
    confirm_prompt "Removing this statement will remove all the entered data/answers associated with it. Are you sure you want to do this? This cannot be undone"
    within form_field_settings_for 'My Likert scale Field' do
      within('.field-options[data-type="statement"]') {expect(page).to have_no_content('Second Option')}
    end
    within form_field_settings_for 'My Likert scale Field' do
      within('.field-options[data-type="statement"] .field-option:nth-child(3)'){ click_js_link 'Remove this option' }
    end
    confirm_prompt "Are you sure you want to remove this statement?"
    within form_field_settings_for 'My Likert scale Field' do
      expect(page).to have_no_content('Statement 3')
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
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    text_field.drag_to form_builder

    expect(form_builder).to have_form_field('Single line text')

    form_field_settings_for 'Single line text'
    within form_builder.find('.field.selected') do
      click_js_link 'Remove'
    end

    confirm_prompt "Are you sure you want to remove this field?"

    expect(form_builder).to_not have_form_field('Single line text')

    # Save the form, should not create any field
    expect {
      click_js_button 'Save'
      wait_for_ajax
    }.to_not change(FormField, :count)
  end

  scenario "user can remove an existing field from the form" do
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    text_field.drag_to form_builder

    expect(form_builder).to have_form_field('Single line text')
    # Save the form
    expect {
      click_js_button 'Save'
      wait_for_ajax
    }.to change(FormField, :count).by(1)

    visit fieldable_path

    expect(form_builder).to have_form_field('Single line text')

    form_field_settings_for 'Single line text'
    within form_builder.find('.field.selected') do
      click_js_link 'Remove'
    end

    confirm_prompt "Removing this field will remove all the entered data/answers associated with it. Are you sure you want to do this?"

    expect(form_builder).to_not have_form_field('Single line text')

    # Save the form, should not create any field
    expect {
      click_js_button 'Save'
      wait_for_ajax
    }.to change(FormField, :count).by(-1)
  end
end

RSpec.shared_examples "a fieldable element that accept kpis" do
  let(:fieldable_path) { url_for(fieldable, only_path: true) }

  let(:kpi) { FactoryGirl.create(:kpi, name: 'My Custom KPI',
    description: 'my custom kpi description',
    kpi_type: 'number', capture_mechanism: 'integer', company: fieldable.company) }


  scenario "add a kpi to the form" do
    kpi.save
    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    find('.fields-wrapper .accordion-toggle', text: 'KPIs').click

    # Wait for accordeon effect to complate
    within('.fields-wrapper') do
      expect(page).to have_no_content('Dropdown')
    end

    kpi_field(kpi).drag_to form_builder

    # Make sure the KPI is not longer available in the KPIs list
    within('.fields-wrapper') do
      expect(page).to have_no_content('My Custom KPI')
    end

    within form_field_settings_for 'My Custom KPI' do
      fill_in 'Field label', with: 'My Custom KPI'
      unicheck('Required')
    end

    expect(form_builder).to have_form_field('My Custom KPI')

    # Close the field settings form
    form_builder.trigger 'click'
    expect(page).to have_no_selector('.field-attributes-panel')

    # Save the form
    expect {
      click_js_button 'Save'
      wait_for_ajax
    }.to change(FormField, :count).by(1)
    field = FormField.last
    expect(field.name).to eql 'My Custom KPI'
    expect(field.type).to eql 'FormField::Number'
    expect(field.kpi_id).to eql field.kpi_id

    within form_field_settings_for 'My Custom KPI' do
      expect(find_field('Field label').value).to eql 'My Custom KPI'
      expect(find_field('Required')['checked']).to be_true
    end

    # Remove the KPI form the form
    form_field_settings_for 'My Custom KPI'
    within form_builder.find('.field.selected') do
      click_js_link 'Remove'
    end

    confirm_prompt "Removing this field will remove all the entered data/answers associated with it. Are you sure you want to do this?"

    # Make sure the KPI is again available in the KPIs list
    within('.fields-wrapper') do
      expect(page).to have_content('My Custom KPI')
    end
  end
end


RSpec.shared_examples "a fieldable element that accept modules" do
  let(:fieldable_path) { url_for(fieldable, only_path: true) }

  scenario "add/remove a module to the form" do

    visit fieldable_path
    expect(page).to have_selector('h2', text: fieldable.name)
    find('.fields-wrapper .accordion-toggle', text: 'Modules').click

    # Wait for accordeon effect to complate
    within('.fields-wrapper') do
      expect(page).to have_no_content('Dropdown')
    end

    module_field('Gallery').drag_to form_builder

    # Make sure the KPI is not longer available in the KPIs list
    within('.fields-wrapper') do
      expect(page).to have_no_content('Gallery')
    end

    expect(find('.form-wrapper')).to have_selector('.form-section.module[data-type=Photos]')

    # Save the form
    click_js_button 'Save'
    wait_for_ajax
    expect(fieldable.reload.enabled_modules).to include('photos')

    visit fieldable_path

    expect(find('.form-wrapper')).to have_selector('.form-section.module[data-type=Photos]')
    within '.form-section.module[data-type=Photos]' do
      click_js_link 'Remove'
    end

    confirm_prompt "Removing this module will remove all the entered data associated with it. Are you sure you want to do this?"

    expect(find('.form-wrapper')).to have_no_selector('.form-section.module[data-type=Photos]')
    click_js_button 'Save'
    wait_for_ajax

    # open the Modules fields list
    find('.fields-wrapper .accordion-toggle', text: 'Modules').click
    # Wait for accordeon effect to complate
    within('.fields-wrapper') do
      expect(page).to have_no_content('Dropdown')
    end

    # The changes were applied in the database
    expect(fieldable.reload.enabled_modules).to be_empty

    # the module should be available again in the list of modules
    expect(find('.fields-wrapper')).to have_content('Gallery')

    expect(find('.form-wrapper')).to have_no_selector('.form-section.module[data-type=Photos]')
    # the module should be available again in the list of modules
    expect(find('.fields-wrapper')).to have_content('Gallery')
  end
end

feature "Campaign Form Builder", js: true do
  let(:user){ FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id) }

  let(:company){  user.companies.first }

  before{ sign_in user }

  it_behaves_like "a fieldable element" do
    let(:fieldable) { FactoryGirl.create(:campaign, company: company) }
    let(:fieldable_path) { campaign_path(fieldable) }
  end

  it_behaves_like "a fieldable element that accept kpis" do
    let(:fieldable) { FactoryGirl.create(:campaign, company: company) }
    let(:fieldable_path) { campaign_path(fieldable) }
  end

  it_behaves_like "a fieldable element that accept modules" do
    let(:fieldable) { FactoryGirl.create(:campaign, company: company) }
    let(:fieldable_path) { campaign_path(fieldable) }
  end

  context "form builder and KPI list integration" do
    let(:campaign) { FactoryGirl.create(:campaign, company: company) }

    scenario "adding a KPI from the list" do
      kpi = FactoryGirl.create(:kpi, name: 'My Custom KPI', company_id: company.id)
      visit campaign_path(campaign)

      # The kpi is in the list of KPIs in the sidebar
      within('.fields-wrapper') do
        expect(page).to have_content('My Custom KPI')
      end

      open_tab 'KPIs'
      click_js_link 'Add KPI'
      within visible_modal do
        fill_in 'Search', with: 'custom'
        expect(page).to have_content 'My Custom KPI'
        click_js_link 'Add KPI'
        expect(page).to have_no_content 'My Custom KPI'
      end
      close_modal

      # Test the field is in the form builder and the KPI
      # was removed from KPIs list in the sidebar
      open_tab 'Post Event form'
      expect(form_builder).to have_form_field 'My Custom KPI'

      within('.fields-wrapper') do
        expect(page).to have_no_content('My Custom KPI')
      end

      # reload page and test the field is still there...
      visit campaign_path(campaign)
      expect(form_builder).to have_form_field 'My Custom KPI'

      # Now test the removal of the KPI from the list
      open_tab 'KPIs'

      within '.kpis-list' do
        expect(page).to have_content 'My Custom KPI'
        click_js_link 'Remove'
      end

      confirm_prompt 'Please confirm you want to remove this KPI?'
      within '.kpis-list' do
        expect(page).to have_no_content 'My Custom KPI'
      end

      open_tab 'Post Event form'

      expect(form_builder).to_not have_form_field 'My Custom KPI'

      # The KPI should be again available in the KPIs list
      within('.fields-wrapper') do
        expect(page).to have_content('My Custom KPI')
      end
    end
  end
end

feature "Activity Types", js: true do
  let(:user){ FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id) }

  let(:company){ user.companies.first }

  before{ sign_in user }

  it_behaves_like "a fieldable element" do
    let (:fieldable) { FactoryGirl.create(:activity_type, name: 'Drink Menu', company: company) }
    let(:fieldable_path) { activity_type_path(fieldable) }
  end
end

def text_area_field
  find('.fields-wrapper .field', text: 'Paragraph')
end

def number_field
  find('.fields-wrapper .field', text: 'Number')
end

def section_field
  find('.fields-wrapper .field', text: 'Section')
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

def kpi_field(kpi)
  find('.fields-wrapper .field', text: kpi.name)
end

def module_field(module_name)
  find('.fields-wrapper .module', text: module_name)
end

def form_builder
  find('.form-fields')
end

def form_field_settings_for(field_name)
  field = field_name
  field = form_field(field_name) if field_name.is_a?(String)
  field.trigger 'click'
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

def form_section(section_name)
  field = nil
  form_builder.all('.field').each do |wrapper|
    field = wrapper if wrapper.all('h3', :text => section_name).count > 0
  end
  raise "Section #{section_name} not found" if field.nil?
  field
end