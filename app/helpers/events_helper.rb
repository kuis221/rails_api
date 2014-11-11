module EventsHelper
  include ActionView::Helpers::NumberHelper
  include SurveySeriesHelper

  def kpi_goal_progress_bar(goal, result)
    return unless goal.present?
    result ||= 0
    bar_widht = [100, result * 100 / goal].min
    bar_widht = 1 if result > 0 && bar_widht < 1   # Display at least one or two pixels
    content_tag(:div, class: 'progress') do
      content_tag(:div, '', class: 'bar', style: "width: #{bar_widht}%")
    end
  end

  def contact_info_tooltip(contact)
    [
      (contact.respond_to?(:title) ? contact.title : contact.role_name),
      contact.email, contact.phone_number, contact.street_address,
      [contact.city, contact.state, contact.country_name].delete_if(&:blank?).join(', ')
    ].delete_if(&:blank?).join('<br />').html_safe
  end

  def allowed_campaigns(venue = nil)
    campaigns = company_campaigns.active.accessible_by_user(current_company_user)
    if venue.present? && !current_company_user.is_admin?
      campaigns.select { |c| c.place_allowed_for_event?(venue.place) }
    else
      campaigns.for_dropdown
    end
  end

  def event_date(event, attribute)
    event.send(attribute)
  end

  def describe_filters
    first_part = [describe_date_ranges, describe_brands, describe_campaigns, describe_areas].compact.join(' ').strip
    first_part = "for: #{first_part}" unless first_part.blank?
    [
      pluralize(number_with_delimiter(collection_count),
                "#{[describe_status, resource_class.model_name.human.downcase].compact.join(' ')}"),
      'found',
      [first_part, describe_people].compact.join(' and ')
    ].compact.join(' ').strip.html_safe
  end

  def describe_before_event_alert(resource)
    description = 'Your event is scheduled.'
    alert_parts = []
    if can?(:view_members, resource) && (can?(:add_members, resource) || can?(:delete_member, resource))
      alert_parts.push "<a href=\"#event-members\" class=\"smooth-scroll\">manage the event team</a>"
    end
    if can?(:tasks, resource)
      alert_parts.push "<a href=\"#event-tasks\" class=\"smooth-scroll\">complete tasks</a>"
    end
    if can?(:index_documents, resource) && can?(:create_document, resource)
      alert_parts.push "<a href=\"#event-documents\" class=\"smooth-scroll\">upload event documents</a>"
    end
    description += ' You can ' + alert_parts.compact.to_sentence unless alert_parts.empty?
    description.html_safe
  end

  def describe_today_event_alert(resource)
    description = 'Your event is scheduled for today. '
    alert_parts = []
    alert_parts.push "<a href=\"#event-results-form\" class=\"smooth-scroll\">enter post event data</a>" if can?(:view_data, resource) && can?(:edit_data, resource)
    alert_parts.push "<a href=\"#event-photos\" class=\"smooth-scroll\">upload photos</a>" if resource.campaign.enabled_modules.include?('photos') && can?(:photos, resource) && can?(:create_photo, resource)
    alert_parts.push "<a href=\"#event-surveys\" class=\"smooth-scroll\">conduct surveys</a>" if resource.campaign.enabled_modules.include?('surveys') && can?(:surveys, resource) && can?(:create_survey, resource)
    alert_parts.push "<a href=\"#event-expenses\" class=\"smooth-scroll\">enter expenses</a>" if resource.campaign.enabled_modules.include?('expenses') && can?(:expenses, resource) && can?(:create_expense, resource)
    alert_parts.push "<a href=\"#event-comments\" class=\"smooth-scroll\">gather comments</a>" if resource.campaign.enabled_modules.include?('comments') && can?(:comments, resource) && can?(:create_comment, resource)
    unless alert_parts.empty?
      description += 'Please ' + alert_parts.compact.to_sentence + ' from your audience during or shortly after the event.'
    end
    description.html_safe
  end

  def describe_due_event_alert(resource)
    description = 'Your post event report is due. '
    alert_parts = []
    alert_parts.push "<a href=\"#event-results-form\" class=\"smooth-scroll\">enter post event data</a>" if can?(:view_data, resource) && can?(:edit_data, resource)
    alert_parts.push "<a href=\"#event-photos\" class=\"smooth-scroll\">upload photos</a>" if resource.campaign.enabled_modules.include?('photos') && can?(:photos, resource) && can?(:create_photo, resource)
    alert_parts.push "<a href=\"#event-surveys\" class=\"smooth-scroll\">conduct surveys</a>" if resource.campaign.enabled_modules.include?('surveys') && can?(:surveys, resource) && can?(:create_survey, resource)
    alert_parts.push "<a href=\"#event-expenses\" class=\"smooth-scroll\">enter expenses</a>" if resource.campaign.enabled_modules.include?('expenses') && can?(:expenses, resource) && can?(:create_expense, resource)
    alert_parts.push "<a href=\"#event-comments\" class=\"smooth-scroll\">gather comments</a>" if resource.campaign.enabled_modules.include?('comments') && can?(:comments, resource) && can?(:create_comment, resource)
    unless alert_parts.empty?
      description += 'Please ' + alert_parts.compact.to_sentence + ' now.'
    end
    description.html_safe
  end

  def describe_late_event_alert(resource)
    description = 'Your post event report is late. '
    alert_parts = []
    alert_parts.push "<a href=\"#event-results-form\" class=\"smooth-scroll\">submit post event data</a>" if can?(:view_data, resource) && can?(:edit_data, resource)
    alert_parts.push "<a href=\"#event-photos\" class=\"smooth-scroll\">upload photos</a>" if resource.campaign.enabled_modules.include?('photos') && can?(:photos, resource) && can?(:create_photo, resource)
    alert_parts.push "<a href=\"#event-surveys\" class=\"smooth-scroll\">complete surveys</a>" if resource.campaign.enabled_modules.include?('surveys') && can?(:surveys, resource) && can?(:create_survey, resource)
    alert_parts.push "<a href=\"#event-expenses\" class=\"smooth-scroll\">enter expenses</a>" if resource.campaign.enabled_modules.include?('expenses') && can?(:expenses, resource) && can?(:create_expense, resource)
    alert_parts.push "<a href=\"#event-comments\" class=\"smooth-scroll\">enter comments</a>" if resource.campaign.enabled_modules.include?('comments') && can?(:comments, resource) && can?(:create_comment, resource)
    unless alert_parts.empty?
      description += 'Please ' + alert_parts.compact.to_sentence + ' now.'
    end
    description.html_safe
  end

  def describe_date_ranges
    start_date = params.key?(:start_date) &&  params[:start_date] != '' ? params[:start_date] : false
    end_date = params.key?(:end_date) &&  params[:end_date] != '' ? params[:end_date] : false
    start_date_d = end_date_d = nil
    start_date_d = Timeliness.parse(start_date).to_date if start_date
    end_date_d = Timeliness.parse(end_date).to_date if end_date
    unless start_date.nil? || end_date.nil?
      today = Time.current.to_date
      yesterday = (Time.current - 1.day).to_date
      tomorrow = (Time.current + 1.day).to_date
      start_date_label = (start_date_d == today ?  'today' : (start_date_d == yesterday ? 'yesterday' : (start_date_d == tomorrow ? 'tomorrow' : Timeliness.parse(start_date).strftime('%B %d')))) if start_date
      end_date_label = (end_date_d == today ? 'today' : (end_date == yesterday.to_s(:slashes) ? 'yesterday' : (end_date_d == tomorrow ? 'tomorrow' : (Timeliness.parse(end_date).strftime('%Y').to_i > Time.zone.now.year + 1 ? 'the future' : Timeliness.parse(end_date).strftime('%B %d'))))) if end_date

      verb = (end_date && end_date_d < today) ? 'took' : 'taking'

      if start_date && end_date && (start_date != end_date)
        if start_date_label == 'today' && end_date_label == 'the future'
          "#{verb} place today and in the future"
        else
          "#{verb} place between #{start_date_label} and #{end_date_label}"
        end
      elsif start_date
        if start_date_d == today
          "#{verb} place today"
        elsif start_date_d >= today
          start_date_label = "at #{start_date_label}" if Timeliness.parse(start_date).strftime('%B %d') == start_date_label
          "#{verb} place #{start_date_label}"
        else
          start_date_label = "on #{start_date_label}" if Timeliness.parse(start_date).strftime('%B %d') == start_date_label
          "#{verb} place #{start_date_label}"
        end
      end
    end
  end

  def build_filter_object_list(filter_name, list)
    list.map do |item|
      content_tag(:div,  class: 'filter-item') do
        item[1].html_safe + link_to('', '#', class: 'icon icon-close',
                                             data: { filter: "#{filter_name}:#{item[0]}" })
      end
    end.join.html_safe
  end

  def describe_campaigns
    campaigns = campaing_params
    return unless campaigns.size > 0
    build_filter_object_list 'campaign',
                             current_company.campaigns
                             .where(id: campaigns)
                             .order('campaigns.name ASC')
                             .pluck(:id, :name)
  end

  def campaing_params
    campaigns = params[:campaign]
    campaigns = [campaigns] unless campaigns.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^campaign,/
      campaigns.push params[:q].gsub('campaign,', '')
    end
    campaigns.compact
  end

  def describe_areas
    areas = area_params
    return unless areas.size > 0
    names = current_company.areas.select('name')
      .where(id: areas).map(&:name).sort.to_sentence(
        last_word_connector: ', or ', two_words_connector: ' or ')
    "in #{names}"
  end

  def area_params
    areas = params[:area]
    areas = [areas] unless areas.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^area,/
      areas.push params[:q].gsub('area,', '')
    end
    areas.compact
  end

  def describe_cities
    cities = city_params
    return unless cities.size > 0
    names = cities.sort.to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')
    "in #{names}"
  end

  def city_params
    cities = params[:city]
    cities = [cities] unless cities.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^city,/
      cities.push params[:q].gsub('city,', '')
    end
    cities.compact
  end

  def describe_locations
    places = location_params
    place_ids = places.select { |p| p =~  /^[0-9]+$/ }
    encoded_locations = places - place_ids
    names = []
    if place_ids.size > 0
      names = Place.select('name').where(id: place_ids).map(&:name)
    end

    if encoded_locations.size > 0
      names.concat(encoded_locations.map do |l|
        (_, name) =  Base64.decode64(l).split('||')
        name
      end)
    end

    "in #{names.to_sentence}" if names.size > 0
  end

  def location_params
    locations = params[:place]
    locations = [locations] unless locations.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^place,/
      locations.push params[:q].gsub('place,', '')
    end
    locations.compact
  end

  def describe_brands
    brands = brand_params
    return unless brands.size > 0
    names = Brand.select('name').where(id: brands).pluck(:name)
    "for #{names.to_sentence}"
  end

  def brand_params
    brands = params[:brand]
    brands = [brands] unless brands.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^brand,/
      brands.push params[:q].gsub('brand,', '')
    end
    brands.compact
  end

  def describe_people
    users = user_params
    names = []
    names = company_users.where(id: users).map(&:full_name) if users.size > 0

    teams = team_params
    names.concat company_teams.where(id: teams).map(&:name) if teams.size > 0

    return unless names.size > 0

    names = names.sort { |a, b| a.downcase <=> b.downcase }
    "assigned to #{names.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')}"
  end

  def user_params
    users = params[:user]
    users = [users] unless users.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^user,/
      users.push params[:q].gsub('user,', '')
    end
    users.compact
  end

  def team_params
    teams = params[:team]
    teams = [teams] unless teams.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^team,/
      teams.push params[:q].gsub('team,', '')
    end
    teams.compact
  end

  def describe_status
    status = params[:status]
    status = [status] unless status.is_a?(Array)

    event_status = params[:event_status]
    event_status = [event_status] unless event_status.is_a?(Array)

    statuses = (status + event_status).uniq.compact
    return if statuses.empty? || statuses.nil?
    [
      status.uniq.to_sentence(last_word_connector: ', or ', two_words_connector: ' or '),
      event_status.uniq.to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')
    ].reject { |s| s.nil? || s.empty? }.to_sentence
  end
end
