require "base64"

module ApplicationHelper
  def place_address(place)
    if !place.nil?
      address = Array.new
      city_parts = []
      address.push place.name unless place.name == place.city
      address.push place.street unless place.street.nil? || place.street.strip.empty? || place.name == place.street
      city_parts.push place.city if place.city
      city_parts.push place.state if place.state
      city_parts.push place.zipcode if place.zipcode
      address.push city_parts.join(', ') unless city_parts.empty? || !place.city
      address.push place.formatted_address if place.formatted_address && city_parts.empty? && (place.city || !place.types.include?('political'))

      "<address>#{address.compact.join('<br />')}</address>".html_safe
    end
  end

  def resource_details_bar(title, url)
    content_for :details_bar do
      content_tag(:div, id: 'resource-close-details') do
        link_to(:back) do
          content_tag(:span, "&times;".html_safe, class: :close) +
          content_tag(:span, title) +
          content_tag(:span, 'Click to close.', class: 'details-bar-pull-right')
        end
      end
    end
  end

  def comment_date(comment)
    if comment.created_at  <= 4.days.ago.end_of_day
      comment.created_at.strftime('%B %e at %l:%M %P')
    elsif comment.created_at  <= 2.days.ago.end_of_day
      comment.created_at.strftime('%A at %l:%M %P')
    elsif comment.created_at <= (Time.zone.now - 24.hours)
      comment.created_at.strftime('Yesterday at %l:%M %P')
    elsif comment.created_at <= (Time.zone.now - 1.hours)
      hours = ((Time.zone.now - comment.created_at)  / 3600).to_i
      if hours == 1
        'about an hour ago'
      else
        comment.created_at.strftime("#{pluralize(hours, 'hour')} ago")
      end
    elsif comment.created_at > (Time.zone.now - 1.hours) and comment.created_at < Time.zone.now
      minutes = ((Time.zone.now - comment.created_at)  / 60).to_i
      comment.created_at.strftime("about #{pluralize(minutes, 'minute')} ago")
    end
  end

  def format_date_with_time(the_date)
    the_date.strftime('%^a <b>%b %e</b> at %l:%M %p').html_safe
  end

  def format_date(the_date)
    the_date.strftime('%^a <b>%b %e</b>').html_safe unless the_date.nil?
  end

  def format_date_range(start_at, end_at)
    if start_at.to_date != end_at.to_date
      format_date_with_time(start_at) +
      '<br />'.html_safe +
      format_date_with_time(end_at)
    else
      start_at.strftime('%^a <b>%b %e</b><br />').html_safe +
      "#{start_at.strftime('%l:%M %p').strip} - #{end_at.strftime('%l:%M %p').strip}".html_safe
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
