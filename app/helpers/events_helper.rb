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

  def describe_filters(resource_name=nil)
    resource_name ||= resource_class.model_name.human.downcase
    first_part = [
      describe_status, describe_prices, describe_custom_date_ranges,
      describe_brands, describe_brand_portfolios, describe_campaigns,
      describe_areas, describe_places, describe_venues, describe_cities, describe_users,
      describe_teams, describe_roles, describe_activity_types, describe_date_ranges,
      describe_day_parts, describe_tasks, describe_range_filters, describe_tags,
      describe_rating, describe_custom_filters
    ].compact.join(' ').strip
    first_part = "for: #{first_part}" unless first_part.blank?
    [
      '<span class="results-count">' + number_with_delimiter(collection_count) + '</span> ' +
      resource_name.pluralize(collection_count),
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

  def describe_custom_date_ranges
    start_date = params[:start_date].blank? ? nil : params[:start_date]
    end_date = params[:end_date].blank? ? nil : params[:end_date]
    return if start_date.nil?
    dates = [start_date, end_date].compact.map { |d| Timeliness.parse(d).to_date }.map do |d|
      if d == Time.current.to_date
        'today'
      elsif d == (Time.current - 1.day).to_date
        'yesterday'
      elsif d == (Time.current + 1.day).to_date
        'tomorrow'
      else
        d
      end
    end

    dates =
      if dates.count > 1 && dates[1].is_a?(Date) && (dates[1].year > Time.zone.now.year + 2)
        "#{dates[0].is_a?(Date) ? dates[0].to_s(:simple_short) : dates[0]} to the future"
      else
        dates.map{ |d| d.is_a?(Date) ? d.to_s(:simple_short) : d }.join(' - ')
      end
    build_filter_object_item dates, "date"
  end

  def describe_range_filters
    params.select{ |k, v| v.is_a?(Hash) && v.key?(:max) && v.key?(:min) }.map do |k, v|
      build_filter_object_item "#{I18n.t('range_filters.' + k.to_s)} between #{v[:min]} and #{v[:max]}", k
    end
  end

  def describe_campaigns
    describe_resource_params(:campaign,
                             current_company.campaigns.order('campaigns.name ASC'))
  end

  def describe_areas
    describe_resource_params(:area,
                             current_company.areas.order('areas.name ASC'),
                             expandible: true)
  end

  def describe_tasks
    describe_resource_params(:task,
                             Task.by_companies(current_company).order('tasks.title ASC'), label_attribute: :title)
  end

  def describe_activity_types
    describe_resource_params(:activity_type,
                             current_company.activity_types.order('activity_types.name ASC'))
  end

  def describe_date_ranges
    describe_resource_params(:date_range,
                             current_company.date_ranges.order('date_ranges.name ASC'))
  end

  def describe_day_parts
    describe_resource_params(:day_part,
                             current_company.day_parts.order('day_parts.name ASC'))
  end

  def describe_brands
    describe_resource_params(:brand,
                             current_company.brands.order('brands.name ASC'))
  end

  def describe_places
    describe_resource_params(:place,
                             Place.order('places.name ASC'))
  end

  def describe_brand_portfolios
    describe_resource_params(:brand_portfolio,
                             current_company.brand_portfolios.order('brand_portfolios.name ASC'),
                             expandible: true)
  end

  def describe_cities
    build_filter_object_list :city, filter_params(:city).map{ |city| [city,city] }
  end

  def describe_prices
    prices = {
      '1' => '$',
      '2' => '$$',
      '3' => '$$$',
      '4' => '$$$$',
    }
    build_filter_object_list :price, filter_params(:price).map{ |price| [price, prices[price]] }
  end


  def describe_venues
    describe_resource_params(:venue,
                             current_company.venues.joins(:place).order('places.name ASC'))
  end

  def describe_users
    describe_resource_params(
      :user,
      current_company.company_users.joins(:user).order('2 ASC'),
      label_attribute: 'users.first_name || \' \' || users.last_name as name')
  end

  def describe_teams
    describe_resource_params(:team,
                             current_company.teams.order('teams.name ASC'),
                             expandible: true)
  end

  def describe_roles
    describe_resource_params(:role,
                             current_company.roles.order('roles.name ASC'))
  end

  def describe_status
    status = filter_params(:status).sort
    event_status = filter_params(:event_status).sort
    task_status = filter_params(:task_status).sort
    [
      build_filter_object_list(:status, status.map{ |status| [status,status] }),
      build_filter_object_list(:event_status, event_status.map{ |status| [status,status] }),
      build_filter_object_list(:task_status, task_status.map{ |status| [status,status] })
    ].compact.join(' ')
  end

  def describe_tags
    describe_resource_params(:tag,
                             current_company.tags.order('tags.name ASC'))
  end

  def describe_rating
    ratings = {
      '0' => '0 stars',
      '1' => '1 star',
      '2' => '2 stars',
      '3' => '3 stars',
      '4' => '4 stars',
      '5' => '5 stars'
    }
    build_filter_object_list :rating, filter_params(:rating).map{ |rating| [rating, ratings[rating]] }
  end

  def describe_custom_filters
    custom_filter = CustomFilter.for_company_user(current_user.current_company_user)
            .order('custom_filters.name ASC')
    describe_resource_params(:cfid,
                             custom_filter, expandible: true)
  end

  def filter_params(param_name)
    ids = params[param_name]
    ids = [ids] unless ids.is_a?(Array)
    if params.key?(:q) && params[:q] =~ /^#{param_name},/
      ids.push params[:q].gsub("#{param_name},", '').strip
    end
    ids.compact.uniq
  end

  def describe_resource_params(param_name, base_scope, label_attribute: :name, expandible: false)
    ids = filter_params(param_name)
    return unless ids.size > 0
    build_filter_object_list param_name,
                             base_scope.where(id: ids).pluck(:id, label_attribute),
                             expandible: expandible
  end

  def build_filter_object_list(filter_name, list, expandible: false)
    return if list.blank?
    list.map do |item|
      build_filter_object_item item[1], "#{filter_name}:#{item[0]}", expandible: expandible
    end.join(' ').html_safe
  end

  def build_filter_object_item(label, filter_name, expandible: false)
    content_tag(:div,  class: 'filter-item') do
      (expandible ? link_to('', '#', class: 'icon icon-plus',
                                     title: 'Expand this filter',
                                     data: { filter: filter_name }) : ''.html_safe) +
      label.html_safe + link_to('', '#', class: 'icon icon-close',
                                         title: 'Remove this filter',
                                         data: { filter: filter_name })
    end
  end

end
