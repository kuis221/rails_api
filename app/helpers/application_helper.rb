module ApplicationHelper
  def place_address(place)
    br = tag(:br)
    content_tag :address do
      (place.name +
      (place.street ? br + place.street : '') +
      br +
      (place.city ? place.city + ', ' : '') +
      place.state +
      (place.zipcode ? ' ' + place.zipcode : '')).html_safe
    end
  end
end
