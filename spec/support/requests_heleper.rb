
module CapybaraBrandscopicHelpers

  def click_ajax_link(locator, options={})
    find(:link, locator, options).trigger('click')
  end

  def object_row(object)
    find("tr##{object.class.name.underscore.downcase}-#{object.id}")
  end
end


module RequestsHelper
  extend RSpec::Matchers::DSL

  include CapybaraBrandscopicHelpers
  def assert_table_sorting(table)
    within table do
      count = all('tbody tr').count
      ids = all('tbody tr').map {|row| row['id']}
      all('thead th[data-sort]').each do |th|
        page.execute_script("$('#{table} tbody').empty()")
        all('tbody tr').count.should == 0
        th.click
        find('tbody tr:first-child') # Wait until the rows have been loaded
        all('tbody tr').count.should == count
        new_ids = all('tbody tr').map {|row| row['id']}
        new_ids.should =~ ids
      end
    end
  end

  matcher :have_error do |text|
    match_for_should { |node| find("span[for=#{node['id']}].help-inline").has_content?(text) }
    match_for_should_not { |node| find("span[for=#{node['id']}].help-inline").has_no_content?(text) }
  end

  def visible_modal
    find('.modal', visible: true)
  end

  def modal_footer
    find('.modal .modal-footer')
  end



  def ensure_on(path)
    visit(path) unless current_path == path
  end

  def login
    Warden.test_mode!
    user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in user
    user.current_company = user.companies.first
    user
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
