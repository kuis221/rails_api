module EventsHelper
  include ActionView::Helpers::NumberHelper
  include SurveySeriesHelper

  def kpi_goal_progress_bar(goal, result)
    if goal.present?
      result ||= 0
      bar_widht = [100, result * 100 / goal].min
      bar_widht = 1 if result > 0 && bar_widht < 1   # Display at least one or two pixels
      content_tag(:div, class: 'progress') do
        content_tag(:div, '', class: 'bar', style: "width: #{bar_widht}%")
      end
    end
  end

  def contact_info_tooltip(contact)
    [(contact.respond_to?(:title) ? contact.title : contact.role_name), contact.email, contact.phone_number, contact.street_address, [contact.city, contact.state, contact.country_name].reject{|v| v.nil? || v == ''}.join(', ') ].reject{|v| v.nil? || v == ''}.join('<br />').html_safe
  end

  def allowed_campaigns(venue = nil)
    campaigns = company_campaigns.active.accessible_by_user(current_company_user)
    campaigns = campaigns.select{|c| c.place_allowed_for_event?(venue.place) } if venue.present? && !current_company_user.is_admin?
    campaigns
  end

  def event_date(event, attribute)
    date = event.send(attribute)
    date = Timeliness.parse(date.in_time_zone(event.timezone).strftime('%Y-%m-%d %H:%M:%S'), zone: event.timezone) if current_company.timezone_support? && event.timezone.present?
    date
  end

  protected

    def describe_before_event_alert(resource)
      description = 'Your event is scheduled. '
      alert_parts = []
      alert_parts.push "<a href=\"#event-members\" class=\"smooth-scroll\">manage the event team</a>" if can?(:view_members, resource) && (can?(:add_members, resource) || can?(:delete_member, resource))
      alert_parts.push "<a href=\"#event-tasks\" class=\"smooth-scroll\">complete tasks</a>" if can?(:tasks, resource)
      alert_parts.push "<a href=\"#event-documents\" class=\"smooth-scroll\">upload event documents</a>" if can?(:index_documents, resource) && can?(:create_document, resource)
      unless alert_parts.empty?
        description += 'You can ' + alert_parts.compact.to_sentence
      end
      description.html_safe
    end

    def describe_today_event_alert(resource)
      description = 'Your event is scheduled for today. '
      alert_parts = []
      alert_parts.push "<a href=\"#event-results-form\" class=\"smooth-scroll\">enter post event data</a>" if can?(:view_data, resource) && can?(:edit_data, resource)
      alert_parts.push "<a href=\"#event-photos\" class=\"smooth-scroll\">upload photos</a>" if resource.campaign.active_field_types.include?('photos') && can?(:photos, resource) && can?(:create_photo, resource)
      alert_parts.push "<a href=\"#event-surveys\" class=\"smooth-scroll\">conduct surveys</a>" if resource.campaign.active_field_types.include?('surveys') && can?(:surveys, resource) && can?(:create_survey, resource)
      alert_parts.push "<a href=\"#event-expenses\" class=\"smooth-scroll\">enter expenses</a>" if resource.campaign.active_field_types.include?('expenses') && can?(:expenses, resource) && can?(:create_expense, resource)
      alert_parts.push "<a href=\"#event-comments\" class=\"smooth-scroll\">gather comments</a>" if resource.campaign.active_field_types.include?('comments') && can?(:comments, resource) && can?(:create_comment, resource)
      unless alert_parts.empty?
        description += 'Please ' + alert_parts.compact.to_sentence + ' from your audience during or shortly after the event.'
      end
      description.html_safe
    end

    def describe_due_event_alert(resource)
      description = 'Your post event report is due. '
      alert_parts = []
      alert_parts.push "<a href=\"#event-results-form\" class=\"smooth-scroll\">enter post event data</a>" if can?(:view_data, resource) && can?(:edit_data, resource)
      alert_parts.push "<a href=\"#event-photos\" class=\"smooth-scroll\">upload photos</a>" if resource.campaign.active_field_types.include?('photos') && can?(:photos, resource) && can?(:create_photo, resource)
      alert_parts.push "<a href=\"#event-surveys\" class=\"smooth-scroll\">conduct surveys</a>" if resource.campaign.active_field_types.include?('surveys') && can?(:surveys, resource) && can?(:create_survey, resource)
      alert_parts.push "<a href=\"#event-expenses\" class=\"smooth-scroll\">enter expenses</a>" if resource.campaign.active_field_types.include?('expenses') && can?(:expenses, resource) && can?(:create_expense, resource)
      alert_parts.push "<a href=\"#event-comments\" class=\"smooth-scroll\">gather comments</a>" if resource.campaign.active_field_types.include?('comments') && can?(:comments, resource) && can?(:create_comment, resource)
      unless alert_parts.empty?
        description += 'Please ' + alert_parts.compact.to_sentence + ' now.'
      end
      description.html_safe
    end

    def describe_late_event_alert(resource)
      description = 'Your post event report is late. '
      alert_parts = []
      alert_parts.push "<a href=\"#event-results-form\" class=\"smooth-scroll\">submit post event data</a>" if can?(:view_data, resource) && can?(:edit_data, resource)
      alert_parts.push "<a href=\"#event-photos\" class=\"smooth-scroll\">upload photos</a>" if resource.campaign.active_field_types.include?('photos') && can?(:photos, resource) && can?(:create_photo, resource)
      alert_parts.push "<a href=\"#event-surveys\" class=\"smooth-scroll\">complete surveys</a>" if resource.campaign.active_field_types.include?('surveys') && can?(:surveys, resource) && can?(:create_survey, resource)
      alert_parts.push "<a href=\"#event-expenses\" class=\"smooth-scroll\">enter expenses</a>" if resource.campaign.active_field_types.include?('expenses') && can?(:expenses, resource) && can?(:create_expense, resource)
      alert_parts.push "<a href=\"#event-comments\" class=\"smooth-scroll\">enter comments</a>" if resource.campaign.active_field_types.include?('comments') && can?(:comments, resource) && can?(:create_comment, resource)
      unless alert_parts.empty?
        description += 'Please ' + alert_parts.compact.to_sentence + ' now.'
      end
      description.html_safe
    end

    def describe_filters
      first_part  = "#{describe_date_ranges} #{describe_brands} #{describe_campaigns} #{describe_locations}".strip
      first_part = nil if first_part.empty?
      second_part  = "#{describe_people}".strip
      second_part = nil if second_part.empty?

      "#{view_context.pluralize(number_with_delimiter(collection_count), "#{describe_status} event")} #{[first_part, second_part].compact.join(' and ')}"
    end

    def describe_date_ranges
      description = ''
      start_date = params.has_key?(:start_date) &&  params[:start_date] != '' ? params[:start_date] : false
      end_date = params.has_key?(:end_date) &&  params[:end_date] != '' ? params[:end_date] : false
      start_date_d = end_date_d = nil
      start_date_d = Timeliness.parse(start_date).to_date if start_date
      end_date_d = Timeliness.parse(end_date).to_date if end_date
      unless start_date.nil? or end_date.nil?
        today = Date.today
        yesterday = Date.yesterday
        tomorrow = Date.tomorrow
        start_date_label = (start_date_d == today ?  'today' : (start_date_d == yesterday ? 'yesterday' : (start_date_d == tomorrow ? 'tomorrow' : Timeliness.parse(start_date).strftime('%B %d') ))) if start_date
        end_date_label = (end_date_d == today ? 'today' : (end_date == yesterday.to_s(:slashes) ? 'yesterday' : (end_date == tomorrow.to_s(:slashes) ? 'tomorrow' : (Timeliness.parse(end_date).strftime("%Y").to_i > Time.zone.now.year+1 ? 'the future' : Timeliness.parse(end_date).strftime('%B %d'))))) if end_date

        if start_date and end_date and (start_date != end_date)
          if Timeliness.parse(end_date) < today
            description = "took place from #{start_date_label} to #{end_date_label}"
          else
            description = "taking place from #{start_date_label} to #{end_date_label}"
          end
        elsif start_date
          if start_date_d == today
            description = "taking place today"
          elsif start_date_d >= today
            start_date_label = "at #{start_date_label}" if Timeliness.parse(start_date).strftime('%B %d') == start_date_label
            description = "taking place #{start_date_label}"
          else
            start_date_label = "on #{start_date_label}" if Timeliness.parse(start_date).strftime('%B %d') == start_date_label
            description = "took place #{start_date_label}"
          end
        end
      end

      description
    end

    def describe_campaigns
      campaigns = campaing_params
      if campaigns.size > 0
        names = current_company.campaigns.select('name').where(id: campaigns).map(&:name).to_sentence(last_word_connector: ' and ')
        "as part of #{names}"
      else
        ""
      end
    end

    def campaing_params
      campaigns = params[:campaign]
      campaigns = [campaigns] unless campaigns.is_a?(Array)
      if params.has_key?(:q) && params[:q] =~ /^campaign,/
        campaigns.push params[:q].gsub('campaign,','')
      end
      campaigns.compact
    end

    def describe_locations
      places = location_params
      place_ids = places.select{|p| p =~  /^[0-9]+$/}
      encoded_locations = places - place_ids
      names = []
      if place_ids.size > 0
        names = Place.select('name').where(id: place_ids).map(&:name)
      end

      if encoded_locations.size > 0
        names += encoded_locations.map{|l| (id, name) =  Base64.decode64(l).split('||'); name }
      end

      if names.size > 0
        "in #{names.to_sentence(last_word_connector: ' and ')}"
      else
        ""
      end
    end

    def location_params
      locations = params[:place]
      locations = [locations] unless locations.is_a?(Array)
      if params.has_key?(:q) && params[:q] =~ /^place,/
        locations.push params[:q].gsub('place,','')
      end
      locations.compact
    end

    def describe_brands
      brands = brand_params
      names = []
      if brands.size > 0
        names = Brand.select('name').where(id: brands).map(&:name)
        "for #{names.to_sentence(last_word_connector: ' and ')}"
      else
        ""
      end
    end

    def brand_params
      brands = params[:brand]
      brands = [brands] unless brands.is_a?(Array)
      if params.has_key?(:q) && params[:q] =~ /^brand,/
        brands.push params[:q].gsub('brand,','')
      end
      brands.compact
    end

    def describe_people
      users = user_params
      names = []
      if users.size > 0
        names = company_users.where(id: users).map(&:full_name)
      end

      teams = team_params
      if teams.size > 0
        names += company_teams.where(id: teams).map(&:name)
      end

      if names.size > 0
        "assigned to #{names.to_sentence(two_words_connector: ' or ', last_word_connector: ' or ')}"
      else
        ""
      end
    end

    def user_params
      users = params[:user]
      users = [users] unless users.is_a?(Array)
      if params.has_key?(:q) && params[:q] =~ /^user,/
        users.push params[:q].gsub('user,','')
      end
      users.compact
    end

    def team_params
      teams = params[:team]
      teams = [teams] unless teams.is_a?(Array)
      if params.has_key?(:q) && params[:q] =~ /^team,/
        teams.push params[:q].gsub('team,','')
      end
      teams.compact
    end

    def describe_status
      status = params[:status]
      status = [status] unless status.is_a?(Array)

      event_status = params[:event_status]
      event_status = [event_status] unless event_status.is_a?(Array)

      statuses = (status + event_status).uniq.compact
      unless statuses.empty? || statuses.nil?
        statuses.to_sentence(last_word_connector: ' and ')
      end
    end
end
