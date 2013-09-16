require "base64"

module ApplicationHelper
  def place_address(place, link_name = false, line_separator = '<br />')
    if !place.nil?
      place_name = place.name
      place_city = place.city

      if link_name
        venue = Venue.find_by_company_id_and_place_id(current_company.id, place.id)
        if venue.present?
          if place.name == place.city
            place_city = link_to place.city, venue_path(venue)
            place_name = nil
          else
            place_name = link_to place.name, venue_path(venue)
          end
        end
      end

      address = Array.new
      city_parts = []
      address.push place.street unless place.street.nil? || place.street.strip.empty? || place.name == place.street
      city_parts.push place_city if place.city && place.name != place.city
      city_parts.push place.state if place.state
      city_parts.push place.zipcode if place.zipcode
      address.push city_parts.join(', ') unless city_parts.empty? || !place.city
      address.push place.formatted_address if place.formatted_address && city_parts.empty? && (place.city || !place.types.include?('political'))

      address_with_name = ["<span class='address-name'>#{place_name}</span>", address.compact.join(line_separator)].compact.join('<br />')

      "<address>#{address_with_name}</address>".html_safe
    end
  end

  def resource_details_bar(title, url)
    content_tag(:div, id: 'resource-close-details', 'data-spy' => "affix", 'data-offset-top' => "20") do
      link_to(:back, class: 'close-details') do
        content_tag(:span, title, class: 'details-bar-pull-left') +
        content_tag(:span, " ".html_safe, class: :close)
      end
    end
  end

  def rating_stars(rating)
    (rating.times.map do
      content_tag(:i, '', {:class => 'icon-star'})
    end +
    (5-rating).times.map do
      content_tag(:i, '', {:class => 'icon-star-empty'})
    end).join.html_safe
  end

  def comment_date(comment)
    time_ago_in_words(comment.created_at)
  end

  def time_ago_in_words(the_date)
    unless the_date.nil?
      if the_date  <= 4.days.ago.end_of_day
        the_date.strftime('%B %e at %l:%M %P')
      elsif the_date  <= 2.days.ago.end_of_day
        the_date.strftime('%A at %l:%M %P')
      elsif the_date <= (Time.zone.now - 24.hours)
        the_date.strftime('Yesterday at %l:%M %P')
      elsif the_date <= (Time.zone.now - 1.hours)
        hours = ((Time.zone.now - the_date)  / 3600).to_i
        if hours == 1
          'about an hour ago'
        else
          the_date.strftime("#{pluralize(hours, 'hour')} ago")
        end
      elsif the_date > (Time.zone.now - 1.hours) and the_date < Time.zone.now
        minutes = ((Time.zone.now - the_date)  / 60).to_i
        the_date.strftime("about #{pluralize(minutes, 'minute')} ago")
      end
    end
  end

  def format_date_with_time(the_date)
    the_date.strftime('%^a <b>%b %e</b> at %l:%M %p').html_safe unless the_date.nil?
  end

  def format_date(the_date, plain = false)
    if plain
      the_date.strftime('%^a %b %e') unless the_date.nil?
    else
      the_date.strftime('%^a <b>%b %e</b>').html_safe unless the_date.nil?
    end
  end

  def format_time(the_date)
    the_date.strftime('%l:%M %P') unless the_date.nil?
  end

  def format_date_range(start_at, end_at, options={})
    options[:date_separator] ||= '<br />'

    unless start_at.nil?
      return format_date_with_time(start_at) if end_at.nil?

      if start_at.to_date != end_at.to_date
        format_date_with_time(start_at) +
        options[:date_separator].html_safe +
        format_date_with_time(end_at)
      else
        start_at.strftime('%^a <b>%b %e</b>'+options[:date_separator]).html_safe +
        "#{start_at.strftime('%l:%M %p').strip} - #{end_at.strftime('%l:%M %p').strip}".html_safe
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

  def gender_graph(data)
    content_tag(:span4, class: :male) do
      content_tag(:div, "#{data.try(:[],'Male').try(:round) || 0} %", class: 'percent') +
      content_tag(:div, 'MALE', class: 'gender')
    end +
    content_tag(:span4, class: :female) do
      content_tag(:div, "#{data.try(:[],'Female').try(:round) || 0} %", class: 'percent') +
      content_tag(:div, 'FEMALE', class: 'gender')
    end
  end
end
