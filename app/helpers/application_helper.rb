module ApplicationHelper
  def place_address(place)
    br = tag(:br)
    content_tag :address do
      (place.name +
      (place.street ? place.street : '') +
      (place.city ? br + place.city + ', ' : '') +
      place.state +
      (place.zipcode ? ' ' + place.zipcode : '')).html_safe
    end
  end

  def resource_details_bar(title, url)
    content_tag(:div, id: 'resource-close-details', 'data-spy' => "affix", 'data-offset-top' => "0") do
      content_tag(:a, href: url) do
        content_tag(:span, "&times;".html_safe, class: :close) +
        content_tag(:span, title)
      end
    end
  end
end
