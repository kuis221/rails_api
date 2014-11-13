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
    first_part = [
      describe_brands, describe_campaigns, describe_areas, describe_cities,
      describe_users, describe_teams
    ].compact.join(' ').strip
    first_part = "for: #{first_part}" unless first_part.blank?
    [
      pluralize(number_with_delimiter(collection_count),
                resource_class.model_name.human.downcase),
                # "#{[describe_status, resource_class.model_name.human.downcase].compact.join(' ')}"),
      'found',
      first_part
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

  def describe_campaigns
    describe_resource_params(:campaign,
                             current_company.campaigns.order('campaigns.name ASC'))
  end

  def describe_areas
    describe_resource_params(:area,
                             current_company.areas.order('areas.name ASC'))
  end

  def describe_brands
    describe_resource_params(:brand,
                             current_company.brands.order('brands.name ASC'))
  end

  def describe_cities
    cities = filter_params(:city)
    return unless cities.size > 0
    build_filter_object_list :city,
                             cities.map{ |city| [city,city] }
  end

  def describe_users
    describe_resource_params(:user,
                             current_company.company_users.joins(:user)
                             .order('2 ASC'),
                             'users.first_name || \' \' || users.last_name as name')
  end

  def describe_teams
    describe_resource_params(:team,
                             current_company.teams.order('teams.name ASC'))
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

  def filter_params(param_name)
    ids = params[param_name]
    ids = [ids] unless ids.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^#{param_name},/
      ids.push params[:q].gsub("#{param_name},", '').strip
    end
    ids.compact
  end

  def describe_resource_params(param_name, base_scope, label_attribute = :name )
    ids = filter_params(param_name)
    return unless ids.size > 0
    build_filter_object_list param_name,
                             base_scope.where(id: ids).pluck(:id, label_attribute)
  end

  def build_filter_object_list(filter_name, list)
    list.map do |item|
      content_tag(:div,  class: 'filter-item') do
        item[1].html_safe + link_to('', '#', class: 'icon icon-close',
                                             data: { filter: "#{filter_name}:#{item[0]}" })
      end
    end.join(' ').html_safe
  end

end
