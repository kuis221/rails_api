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

  def describe_filters(resource_name = resource_class.model_name.human.downcase)
    tags = FilterTags.new(params, current_company_user).tags do |label, filter_name, expandible, param|
      remove_data = { filter: filter_name }
      if /\Adate:(?<start_date>.*),(?<end_date>.*)\z/ =~ filter_name
        remove_data = { filter: 'date', start_date: start_date, end_date: end_date }
      end
      content_tag(:div,  class: 'filter-item') do
        (if expandible
           link_to('', '#', class: 'icon icon-plus', title: 'Expand this filter',
                            data: { filter: filter_name })
         else
           ''.html_safe
         end) +
        label.html_safe + link_to('', '#', class: 'icon icon-close',
                                           title: 'Remove this filter',
                                           data: remove_data)
      end
    end.join(' ').strip

    self.builder_block = builder_block if block_given?
    resource_name ||= resource_class.model_name.human.downcase
    tags = "for: #{tags}" unless tags.blank?
    [
      '<span class="results-count">' + number_with_delimiter(collection_count) + '</span> ' +
      resource_name.pluralize(collection_count),
      'found',
      tags
    ].compact.join(' ').strip.html_safe
  end

  def allowed_campaigns(venue = nil)
    campaigns = company_campaigns.active.accessible_by_user(current_company_user)
    if venue.present? && !current_company_user.is_admin?
      campaigns.select { |c| c.place_allowed_for_event?(venue.place) }.map { |c| [c.name, c.id] }
    else
      campaigns.for_dropdown
    end
  end

  def event_date(event, attribute)
    event.send(attribute)
  end
end
