module EventsHelper
  include ActionView::Helpers::NumberHelper

  def event_date_range(event)
    if event.start_at.to_date == event.end_at.to_date
      "#{event.start_date} #{event.start_time} - #{event.end_time}"
    else
      "#{event.start_date} #{event.start_time} -  #{event.end_date} #{event.end_time}"
    end
  end

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

  def series_question_1(resource)
    [{
        name: 'UNAWARE',
        color: '#1F8EBC',
        legendIndex: 3,
        data: resource.campaign.survey_brands.map{|b| resource.survey_statistics['question_1']['unaware'][b.name][:avg].round rescue 0 }
    },{
        name: 'AWARE',
        color: '#6DBCE7',
        legendIndex: 2,
        data: resource.campaign.survey_brands.map{|b| resource.survey_statistics['question_1']['aware'][b.name][:avg].round rescue 0 }
    },{
        name: 'PURCHASED',
        color: '#A8DDEF',
        legendIndex: 1,
        data: resource.campaign.survey_brands.map{|b| resource.survey_statistics['question_1']['purchased'][b.name][:avg].round rescue 0 }
    }]
  end

  def series_question_2(resource)
    [{
        name: 'average',
        categories: resource.survey_statistics['question_2'].map{|b, s| b},
        data: resource.survey_statistics['question_2'].map{|b, s| s[:avg].round},
        dataLabels: {
                    enabled: true,
                    format: '${y}',
                    color: '#3E9CCF',
                    align: 'right',
                    x: 0,
                    y: 0,
                    style: { color: '#3E9CCF' }
                }
    }]
  end

  def series_question_3(resource)
    ids = {2 => 'UNLIKELY', 3 => 'NEUTRAL', 5 => 'LIKELY'}
    (1..5).map do |i|
      {
        name: i,
        legendIndex: i,
        color: (i < 3 ? '#A8DDEF' : (i < 4 ? '#6DBCE7' : '#1F8EBC') ),
        data: resource.campaign.survey_brands.map{|b| resource.survey_statistics['question_3'][i.to_s][b.name][:avg].round rescue 0 }
      }.merge(ids.has_key?(i) ?  {id: ids[i]} : {linkedTo: ':previous'})
    end.reverse
  end

  def series_question_4(resource)
    ids = {6 => 'UNLIKELY', 8 => 'NEUTRAL', 10 => 'LIKELY'}
    (1..10).map do |i|
      {
        name: i,
        legendIndex: i,
        color: (i < 7 ? '#A8DDEF' : (i < 9 ? '#6DBCE7' : '#1F8EBC') ),
        data: resource.campaign.survey_brands.map{|b| resource.survey_statistics['question_4'][i.to_s][b.name][:avg].round rescue 0 }
      }.merge(ids.has_key?(i) ?  {id: ids[i]} : {linkedTo: ':previous'})
    end.reverse
  end

  protected

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
        end_date_label = (end_date_d == today ? 'today' : (end_date == yesterday.to_s(:slashes) ? 'yesterday' : (end_date == tomorrow.to_s(:slashes) ? 'tomorrow' : Timeliness.parse(end_date).strftime('%B %d')))) if end_date

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
      if users.size > 0
        names += company_teams.where(id: teams).map(&:name)
      end

      if names.size > 0
        "assigned to #{names.to_sentence(last_word_connector: ' and ')}"
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

      statuses = (status + event_status).compact
      unless statuses.empty? || statuses.nil?
        statuses.to_sentence(last_word_connector: ' and ')
      end
    end
end
