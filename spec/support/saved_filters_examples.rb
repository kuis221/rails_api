RSpec.shared_examples 'a list that allow saving custom filters' do
  scenario 'allows to create apply and remove custom filters' do
    visit list_url

    show_all_filters

    within '#collection-list-filters' do
      expect(page).not_to have_content('SAVED FILTERS')
    end

    filters.each do |filter|
      add_filter filter[:section], filter[:item]
    end

    click_button 'Save'

    within visible_modal do
      fill_in('Filter name', with: 'My Custom Filter')
      expect do
        click_button 'Save'
        wait_for_ajax
      end.to change(CustomFilter, :count).by(1)
    end
    ensure_modal_was_closed

    within '#collection-list-filters' do
      expect(page).to have_content('SAVED FILTERS')
    end

    filters.each do |filter|
      expect(collection_description).to have_filter_tag(filter[:item])
    end

    click_js_button 'Reset'

    filters.each do |filter|
      expect(collection_description).not_to have_filter_tag(filter[:item])
    end

    select_saved_filter 'My Custom Filter'

    filters.each do |filter|
      expect(collection_description).to have_filter_tag(filter[:item])
    end

    # Deselect filter
    click_button 'Reset'

    filters.each do |filter|
      expect(collection_description).not_to have_filter_tag(filter[:item])
    end

    # Apply the saved filter
    select_saved_filter 'My Custom Filter'

    filters.each do |filter|
      expect(collection_description).to have_filter_tag(filter[:item])
    end

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

    within '#collection-list-filters' do
      expect(page).not_to have_content('SAVED FILTERS')
    end
  end
end