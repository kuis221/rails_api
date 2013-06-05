module ApplicationHelper
  def place_address(place)
    br = tag(:br)
    content_tag :address do
      address = Array.new
      city_parts = []
      address.push place.name unless place.name == place.city
      address.push place.street unless place.street.strip.empty? || place.name == place.street
      city_parts.push place.city if place.city
      city_parts.push place.state if place.state
      city_parts.push place.zipcode if place.zipcode
      address.push city_parts.join(', ') unless city_parts.empty? || !place.city
      address.push place.formatted_address if place.formatted_address && city_parts.empty? && (place.city || !place.types.include?('political'))

      address.compact.join(br).html_safe
    end
  end

  def resource_details_bar(title, url)
    content_tag(:div, id: 'resource-close-details', 'data-spy' => "affix", 'data-offset-top' => "0") do
      content_tag(:a, href: url) do
        content_tag(:span, "&times;".html_safe, class: :close) +
        content_tag(:span, title) +
        content_tag(:span, 'Click to close.', class: 'details-bar-pull-right')
      end
    end
  end

  def user_company_dropdown(user)
    if user.companies.size == 1
      link_to user.companies.first.name, root_path, class: 'current-company-title'
    else
      content_tag(:div, class: 'dropdown') do
        text = 'Select Company'
        text = current_company.name if current_company
        link_to((current_company.name + ' ' + content_tag(:b,'', class: 'caret')).html_safe, root_path, class: 'dropdown-toggle current-company-title', 'data-toggle' => 'dropdown') +
        content_tag(:ul, class: 'dropdown-menu', id: 'user-company-dropdown', role: 'menu', 'aria-labelledby' => "dLabel") do
          user.companies.map do |company|
            content_tag(:li, link_to(company.name, select_company_path(company), id: 'select-company-'+company.id.to_s), role: 'presentation')
          end.join('').html_safe
        end
      end
    end
  end
end
