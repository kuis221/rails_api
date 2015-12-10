require 'timeout'
require 'rexml/document'
require 'open-uri'

module CapybaraBrandscopicHelpers
  def wait_for_ajax(timeout = Capybara.default_max_wait_time)
    wait_until(timeout) { page.evaluate_script '((typeof jQuery == "undefined") || (jQuery.active == 0))' }
  end

  def wait_until(timeout = Capybara.default_max_wait_time)
    Timeout.timeout(timeout) do
      sleep(0.1) until value = yield
      value
    end
  end

  def hover_and_click(parent, locator, options = {})
    parent = find(parent) if parent.is_a?(String)
    parent.hover
    within(parent) { expect(page).to have_selector(:link_or_button, locator) }
    parent.find(:link_or_button, locator, options).trigger('click')
    self
  end

  def wait_for_download_to_complete(timeout = Capybara.default_max_wait_time)
    count = ListExport.count
    yield
    Timeout.timeout(timeout) do
      sleep(0.5) until ListExport.count != count
      export = ListExport.last
      sleep(0.5) until export.reload.completed?
    end
  end

  def wait_for_photo_to_process(timeout = Capybara.default_max_wait_time)
    last_modified = AttachedAsset.last.try(:updated_at)
    count = AttachedAsset.count
    yield
    Timeout.timeout(timeout) do
      # Wait until a new attachment is created or the last one is modified (for the cases when updating attachments)
      sleep(0.5) until AttachedAsset.count > count || last_modified != AttachedAsset.last.try(:updated_at)
      photo = AttachedAsset.last
      sleep(0.5) until photo.reload.processed?
    end
  end

  def wait_for_export_to_complete
    within visible_modal do
      expect(page).to have_content('We are processing your request, the download will start soon...')
      ListExportWorker.drain
    end
    ensure_modal_was_closed
  end

  def confirm_prompt(message)
    within find(:xpath, '//div[contains(@class, \'modal\') and contains(@class, \'confirm-dialog\') and contains(@class, \'in\')]', visible: true) do
      expect(page).to have_content(message)
      # For some reason, the click_link function doesn't always works, so we are using JS
      # for this instead
      # click_link("OK")
      page.execute_script("$('.bootbox.modal.confirm-dialog.in a.btn-primary').click()")
    end
    expect(page).to have_no_selector('.modal.confirm-dialog.in', visible: true)
  end

  def click_js_link(locator, options = {})
    find(:link, locator, options).trigger('click') # Use this if using capybara-webkit instead of selenium
    # find(:link, locator, options).click   # For Selenium
    self
  end

  def show_all_filters
    find(:link, 'Show filters').trigger('click') # Use this if using capybara-webkit instead of selenium
    expect(page).to have_link('Hide filters')
  end

  def remove_filter(filter_name)
    wait_for_ajax
    within '.collection-list-description' do
      find('.filter-item', text: filter_name).click_js_link 'Remove this filter'
      expect(page).to have_no_selector('.filter-item', text: filter_name)
    end
  end

  def expand_filter(filter_name)
    wait_for_ajax
    within '.collection-list-description' do
      find('.filter-item', text: filter_name).click_js_link 'Expand this filter'
      expect(page).to have_no_selector('.filter-item', text: filter_name)
    end
  end

  def add_filter(filter_category, filter)
    field = filter_section(filter_category).find_field(filter)
    filter_section(filter_category).unicheck(filter)
    within '.collection-list-description' do
      expect(page).to have_filter_tag(filter) unless field['name'] == 'custom_filter[]'
    end
  end

  def click_js_button(locator, options = {})
    find(:button, locator, options).trigger('click') # Use this if using capybara-webkit instead of selenium
    # find(:button, locator, options).click
    self
  end

  def select_saved_filter(name)
    within '.user-saved-filters' do
      select_from_chosen(name, from: 'user-saved-filter')
    end
  end

  def select_from_chosen(item_text, options)
    field = find_field(options[:from], visible: false)
    field.find('option', text: item_text, visible: false, match: :first).select_option
    page.execute_script("$('##{field[:id]}').trigger('liszt\:updated')")
    wait_for_ajax
  end

  def select_from_autocomplete(selector, text)
    field = find_field(selector)
    page.execute_script %{$('##{field['id']}').val('#{text}').keydown()}
    expect(page).to have_selector('ul.ui-autocomplete li.ui-menu-item a')
    find('ul.ui-autocomplete li.ui-menu-item a', text: text, match: :first).click
  end

  def select_time(time, from: '.timepicker')
    find_field(from).trigger('focus')
    within '.ui-timepicker-list' do
      find('li', text:  /\A#{time}\z/).click
    end
    expect(find_field(from).value).to eql time
  end

  def select2(item_text, options)
    select_name = options[:from]
    select2_container = first('label', text: select_name).find(:xpath, '..').find('.select2-container')
    if select2_container['class'].include?('select2-container-multi')
      select2_container.find('.select2-choices').click
    else
      select2_container.find('.select2-choice').click
    end

    [item_text].flatten.each do |value|
      select2_container.find(:xpath, "a[contains(concat(' ',normalize-space(@class),' '),' select2-choice ')] | ul[contains(concat(' ',normalize-space(@class),' '),' select2-choices ')]").trigger('click')
      find(:xpath, '//body').find('.select2-drop li', text: value).click
    end
    wait_for_ajax
  end

  def select2_add_tag(field_name, tag)
    find('.select2-container').find('.select2-search-field').click
    fill_in field_name, with: tag
    page.execute_script(%|$("input.select2-input:visible").keyup();|)
    [tag].flatten.each do |t|
      find(:xpath, '//body').find('.select2-results li', text: t).click
    end
  end

  def select2_remove_tag(tag)
    page.execute_script %{
      $('.select2-choices div:contains("#{tag}")').closest('li').find('a').click();
    }
  end

  # Selects an option from google places autocomplete
  def select_places_autocomplete(place, from: nil)
    fill_in from, with: place
    field = find_field(from)
    page.execute_script(%|$('##{field['id']}').focus();|)
    page.execute_script(%|google.maps.event.trigger($('##{field['id']}')[0], 'focus', {});|)
    find('.pac-container .pac-item', match: :first).click
    sleep 1 # to give time to the event listeners to be executed
  end

  def select_filter_calendar_day(day1, day2 = nil)
    day2 ||= day1
    find('div.dates-range-filter div.datepick-month').click_js_link(day1).click_js_link(day2)
  end

  def select_and_fill_from_datepicker(_name, date)
    date = date.to_s(:slashes) if date.class.in?([Time, DateTime, Date])
    (month, day, year) = date.split('/')
    day = day.to_i.to_s
    find(:xpath, "//td[@data-year='#{year}' and @data-month='#{month.to_i - 1}']", text: day, match: :prefer_exact).click_js_link(day)
  end

  def unicheck(option)
    cb = nil
    all('label', text: option).each do |label|
      if label['for']
        cb = find('input#' + label['for'], visible: false, match: :first)
      else
        cb = label.find('div.checker', match: :first)
      end
    end
    if cb
      cb.trigger('click')
    else
      fail Capybara::ElementNotFound.new("Unable to find option #{option}")
    end
    cb
  end

  def object_row(object)
    find("tr#{object.class.name.underscore.downcase}-#{object.id}")
  end

  def spreadsheet_from_last_export
    open(URI.parse(ListExport.last.file.url(:original, timestamp: false))) do |file|
      yield REXML::Document.new(file)
    end
  end
end

module RequestsHelper
  extend RSpec::Matchers::DSL

  include CapybaraBrandscopicHelpers

  matcher :have_error do |text|
    match { |node| find("span[for=#{node['id']}].help-inline").has_content?(text) }
    match_when_negated { |node| find("span[for=#{node['id']}].help-inline").has_no_content?(text) }
  end

  matcher :have_hint do |text|
    match { |node| find("#hint-#{node['data-field-id']}").has_content?(text) }
    match_when_negated { |node| find("#hint-#{node['data-field-id']}").has_no_content?(text) }
  end

  def visible_modal
    find('.modal.in', visible: true)
  end

  def collection_description
    find(:xpath, '//div[@class=\'collection-list-description\']')
  end

  def filter_section(title, auto_open: true)
    section = nil
    find('.form-facet-filters .accordion-group .filter-wrapper a', text: title)
    page.all('.form-facet-filters .accordion-group').each do |wrapper|
      if wrapper.all('.filter-wrapper a', text: title).count > 0
        if auto_open
          link = wrapper.find('.filter-wrapper a', text: title, match: :first)
          link.trigger('click') if link[:class].include?('collapsed')
          expect(wrapper).not_to have_selector('a.collapsed', text: title)
        end
        section = wrapper
        break
      end
    end

    section
  end

  def choose_predefined_date_range(option)
    click_js_link 'Date ranges'
    within 'ul.dropdown-menu' do
      click_js_link option
    end
    ensure_date_ranges_was_closed
  end

  def open_tab(tab_name)
    link = find('.nav-tabs a', text: tab_name)
    link.trigger('click')
    find(link['href'].gsub(/^.*#/, '#'))
  end

  def modal_footer
    find('.modal .modal-footer')
  end

  def close_modal
    visible_modal.click_js_link('Close', match: :first)
    ensure_modal_was_closed
  end

  def close_resource_details
    find('a.close-details').click
  end

  def ensure_modal_was_closed
    expect(page).to have_no_selector('.modal.in', visible: true)
  end

  def ensure_date_ranges_was_closed
    expect(page).to have_no_selector('.select-ranges.open', visible: true)
  end

  def ensure_on(path)
    visit(path) unless current_path == path
  end

  def resource_item(resource = 1, list: nil)
    root = page
    root = find(list) unless list.nil?
    item =
      if resource.is_a?(Integer)
        root.find(".resource-item:nth-child(#{resource})")
      elsif resource.is_a?(String)
        root.find(".resource-item#{resource}")
      else
        root.find(".resource-item##{resource.class.name.underscore}_#{resource.id}, .resource-item##{resource.class.name.underscore}-#{resource.id}")
      end
    begin
      item.hover
    rescue Capybara::Poltergeist::MouseEventFailed
      page.evaluate_script 'window.scrollBy(0, -100);'
      item.hover
    end
    item
  end

  def staff_selected?(type, id, selected = false)
    checkbox = find("#staff-member-#{type}-#{id} .resource-item-link input")
    expect(checkbox['checked']).to selected == true ? be_truthy : be_falsey
  end

  def select_from_staff(type, id)
    find("#staff-member-#{type}-#{id} .resource-item-link").trigger('click')
  end
end

module Capybara
  module Node
    module Actions
      include CapybaraBrandscopicHelpers
    end

    class Element < Base
      include CapybaraBrandscopicHelpers
    end
  end
end
