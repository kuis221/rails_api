require "timeout"
require "rexml/document"
require 'open-uri'

module CapybaraBrandscopicHelpers
  def wait_for_ajax(timeout = Capybara.default_wait_time)
    wait_until(timeout) { page.evaluate_script '((typeof jQuery == "undefined") || (jQuery.active == 0))' }
  end

  def wait_until(timeout = Capybara.default_wait_time)
    Timeout.timeout(timeout) do
      sleep(0.1) until value = yield
      value
    end
  end

  def hover_and_click(parent, locator, options={})
    parent_element = find(parent)
    parent_element.hover
    parent_element.find(:link, locator, options).trigger('click')
    self
  end

  def wait_for_download_to_complete(timeout = Capybara.default_wait_time)
    count = ListExport.count
    yield
    Timeout.timeout(timeout) do
      sleep(0.5) until ListExport.count != count
      export = ListExport.last
      sleep(0.5) until export.reload.completed?
    end
  end

  def wait_for_photo_to_process(timeout = Capybara.default_wait_time)
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

  def confirm_prompt(message)
    within find(:xpath, '//div[contains(@class, \'modal\') and contains(@class, \'confirm-dialog\') and contains(@class, \'in\')]', visible: true) do
      expect(page).to have_content(message)
      # For some reason, the click_link function doesn't always works, so we are using JS
      # for this instead
      #click_link("OK")
      page.execute_script("$('.bootbox.modal.confirm-dialog.in a.btn-primary').click()")
    end
    expect(page).to have_no_selector('.modal.confirm-dialog.in', visible: true)
  end

  def click_js_link(locator, options={})
    find(:link, locator, options).trigger('click') # Use this if using capybara-webkit instead of selenium
    #find(:link, locator, options).click   # For Selenium
    self
  end

  def click_js_button(locator, options={})
    find(:button, locator, options).trigger('click') # Use this if using capybara-webkit instead of selenium
    #find(:button, locator, options).click
    self
  end

  def select_from_chosen(item_text, options)
    field = find_field(options[:from], visible: false)
    field.find('option', text: item_text, visible: false, match: :first).select_option
    page.execute_script("$('##{field[:id]}').trigger('liszt\:updated')")
    wait_for_ajax
  end

  def select_from_autocomplete(selector, text)
    field = find_field(selector)
    page.execute_script %Q{$('##{field['id']}').val('#{text}').keydown()}
    find('ul.ui-autocomplete li.ui-menu-item a', match: :first).click
  end


  def select2(item_text, options)
    select_name = options[:from]
    select2_container = first("label", text: select_name).find(:xpath, '..').find(".select2-container")
    if select2_container['class'].include?('select2-container-multi')
      select2_container.find(".select2-choices").click
    else
      select2_container.find(".select2-choice").click
    end

    [item_text].flatten.each do |value|
      select2_container.find(:xpath, "a[contains(concat(' ',normalize-space(@class),' '),' select2-choice ')] | ul[contains(concat(' ',normalize-space(@class),' '),' select2-choices ')]").trigger('click')
      find(:xpath, "//body").find(".select2-drop li", text: value).click
    end
    wait_for_ajax
  end

  def select2_add_tag(field_name, tag)
    find('.select2-container').find(".select2-search-field").click
    fill_in field_name, with: tag
    page.execute_script(%|$("input.select2-input:visible").keyup();|)
    [tag].flatten.each do |t|
      find(:xpath, "//body").find(".select2-results li", text: t).click
    end
  end

  def select2_remove_tag(tag)
    page.execute_script %Q{
      $('.select2-choices div:contains("#{tag}")').closest('li').find('a').click();
    }
  end

  def select_filter_calendar_day(day1, day2=nil)
    day2 ||= day1
    find('div.dates-range-filter div.datepick-month').click_js_link(day1).click_js_link(day2)
  end

  def select_and_fill_from_datepicker(name, date, format = '%m/%d/%y')
    if date.class.in?([Time, DateTime, Date])
      date = date.strftime(format)
    end
    #Click on random date to trigger onSelect event
    page.execute_script %Q{ $("a.ui-state-default:contains('15')").trigger("click") }
    #Fill corresponding field
    wrapped_name = "#{name}"
    id = find(:xpath, "//input[contains(@name, '#{wrapped_name}')]")[:id]
    page.execute_script("$('##{id}').removeAttr('readonly')")
    fill_in name, :with => date
  end

  def unicheck(option)
    found = false
    all('label', text: option).each do |label|
      label.all('div.checker').each do |cb|
        cb.trigger('click')
        found = cb
      end
    end
    raise Capybara::ElementNotFound.new("Unable to find option #{option}") unless found
    found
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

  def visible_modal
    find('.modal.in', visible: true)
  end

  def filter_section(title)
    section = nil
    find('.form-facet-filters h3', text: title)
    page.all('.form-facet-filters .filter-wrapper').each do |wrapper|
      if wrapper.all('h3', :text => title).count > 0
        section = wrapper
        break
      end
    end
    section
  end

  def open_tab(tab_name)
    link = find('.nav-tabs a', text: tab_name)
    link.click
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

  def ensure_on(path)
    visit(path) unless current_path == path
  end

  # Helpers for events section
  def event_team_member(member)
    find('#event-team-members #event-member-'+member.id.to_s)
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create(action: p[0], subject_class: p[1])
    end
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
