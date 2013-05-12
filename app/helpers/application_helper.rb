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
end
