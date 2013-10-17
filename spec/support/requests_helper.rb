
module CapybaraBrandscopicHelpers

  def hover_and_click(parent, locator, options={})
    parent_element = find(parent)
    page.execute_script("$('html, body').animate({
        scrollTop: $('#{parent}').offset().top - 200
    }, 0);")
    page.driver.browser.action.move_to(parent_element.native).perform
    find(:link, locator, options).click
    self
  end

  def click_js_link(locator, options={})
    #find(:link, locator, options).trigger('click') # Use this if using capybara-webkit instead and not selenium
    find(:link, locator, options).click
    self
  end

  def click_js_button(locator, options={})
    #find(:button, locator, options).trigger('click')
    find(:button, locator, options).click
    self
  end

  def select_from_chosen(item_text, options)
    field = find_field(options[:from], visible: false)
    option_value = page.evaluate_script("$(\"##{field[:id]} option:contains('#{item_text}')\").val()")
    page.execute_script("value = ['#{option_value}']\; if ($('##{field[:id]}').val()) {$.merge(value, $('##{field[:id]}').val())}")
    option_value = page.evaluate_script("value")
    page.execute_script("$('##{field[:id]}').val(#{option_value})")
    page.execute_script("$('##{field[:id]}').trigger('liszt:updated').trigger('change')")
  end

  def object_row(object)
    find("tr#{object.class.name.underscore.downcase}-#{object.id}")
  end
end


module RequestsHelper
  extend RSpec::Matchers::DSL

  include CapybaraBrandscopicHelpers

  matcher :have_error do |text|
    match_for_should { |node| find("span[for=#{node['id']}].help-inline").has_content?(text) }
    match_for_should_not { |node| find("span[for=#{node['id']}].help-inline").has_no_content?(text) }
  end

  def visible_modal
    find('.modal.in', visible: true)
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
    visible_modal.click_link('Close')
    ensure_modal_was_closed
  end

  def ensure_modal_was_closed
    page.should have_no_selector('.modal.in', visible: true)
  end

  def ensure_on(path)
    visit(path) unless current_path == path
  end

  def login
    Warden.test_mode!
    user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in user
    User.current = user
    user.current_company = user.companies.first
    user
  end


  # Helpers for events section
  def event_team_member(member)
    find('#event-team-members #event-member-'+member.id.to_s)
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
