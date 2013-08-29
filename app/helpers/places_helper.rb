module PlacesHelper
  def place_website(url)
    link_to url.gsub(/https?:\/\//,'').gsub(/\/$/,''), url
  end

  def venue_score_narrative(venue)
    narrative = begin
      unless venue.score.nil?
        (build_score_narrative(venue) +
        "<p>Attendess at previous events have predominantly been #{predominant(:age, venue)} year old #{predominant(:ethnicity, venue)} #{predominant(:gender, venue)}.").html_safe
      else
        nil
      end
    end

  end

  def build_score_narrative(venue)
    if venue.score_impressions <= 33
      if venue.score_cost <= 33
        "#{venue.name} performs poorly relative to similar venues in the area. Not only is it more expensive per impression but it also appears less popular than other venues. Consider conducting fewer events at this venue."
      elsif venue.score_cost <= 66
        "#{venue.name} is about average inpopularity compared to similar venues in the area though is more expensive per impression. Consider looking for lower cost venues if possible."
      else
        "#{venue.name} is a popular venue compared to similar venues in thearea with heavy patron traffic but above average costs per impression. If less concerned about budget, this could be attractive."
      end
    elsif venue.score_impressions <= 66
      if venue.score_cost <= 33
        "While the cost per impression for #{venue.name} is comparable to similar venues in the area, it has substantially lower patron traffic. Consider looking for more popular venues if possible."
      elsif venue.score_cost <= 66
        "#{venue.name} is about average compared to similar venues in the area both in terms of popularity and cost per impression. Most venues will fallinto this category."
      else
        "#{venue.name} is a popular venue compared to similar venues in the area with heavy patron traffic and average costs per impression. Consider running more events here when  looking to influence more individuals and are within budget."
      end
    else
      if venue.score_cost <= 33
        "While the cost per impressionfor #{venue.name} is lower thansimilar venues in the area, patron traffic also seems lower. Consider only running events here on the busiest nights of the week."
      elsif venue.score_cost <= 66
        "#{venue.name} is a good value for the area with low costs per impression and patron trafficcomparable to similar venues in the area. Consider running more events here when you are concerned about budget."
      else
        "#{venue.name} is an exceptionally strong venue compared to similar venues in the area.  It is both popular and a relatively low cost. Considerrunning more events here whenever possible."
      end
    end

  end

  def venue_trend_week_day_narrative(venue)
    stats = resource.overall_graphs_data[:trends_week_day]
    days_names = %w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
    days_with_events = stats.map{|x,y| days_names[x] if y > 0 }.compact
    days_count = days_with_events.count
    if days_count > 1
      max = stats.values.max
      best_days = stats.select{|x,y| y == max }.keys.map{|d| days_names[d] }
      "#{venue.name} has had events on #{days_with_events.to_sentence} and has performed best on #{best_days.to_sentence}. Specifically, #{venue.name} yields more impressions per hour on #{best_days.to_sentence} than on any other day of the week."
    elsif days_count == 1
      "#{venue.name} has only had events on #{days_with_events.first}. Without having events on other days of the week, it is difficult to draw conclusions about what day of the week has shown the best performance at #{venue.name} in the past."
    end
  end

  def place_opening_hours(opening_hours)
    days = %w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
    if opening_hours && opening_hours.has_key?("periods")
      (0..6).map do |i|
        day = (i == 6 ? 0 : i + 1)
        period = opening_hours['periods'].detect{|p| p['open']['day'].to_i == day }
        day_name = days[day]
        if period
          "#{day_name} #{Time.parse(period['open']['time'].gsub(/(^[0-9]{2})/, '\1:')).to_s(:time_only)} - #{Time.parse(period['close']['time'].gsub(/(^[0-9]{2})/, '\1:')).to_s(:time_only)}"
        else
          "#{day_name} Closed"
        end
      end.join('<br />').html_safe
    end
  end

  private
    def score_calification_for(score)
      if score > 66
        'well relative to'
      elsif score > 33
        'on par with'
      else
        'poorly relative to'
      end
    end

    def predominant(kpi, venue)
      venue.overall_graphs_data[kpi].max_by{|k,v| v}[0]
    end

    def avg_impressions_cost_performance_for(venue)
      if stats = avg_stats_for_venue(venue)
        if venue.avg_impressions_hour > stats[:avg_impressions_cost]
          'higher than'
        elsif  venue.avg_impressions == stats[:avg_impressions_cost]
          'on par with'
        else
          'lower than'
        end
      end
    end


    def avg_impressions_hour_performance_for(venue)
      if stats = avg_stats_for_venue(venue)
        if venue.avg_impressions_hour > stats[:avg_impressions_hour]
          'above average'
        elsif  venue.avg_impressions == stats[:avg_impressions_hour]
          'average'
        else
          'below average'
        end
      end
    end


    def avg_stats_for_venue(venue)
      @stats ||= {}
      @stats[venue.id] ||= begin
        search = Venue.solr_search do
          with(:company_id, venue.company_id)
          with(:location).in_radius(venue.latitude, venue.longitude, 5)
          with(:types, venue.types_without_establishment )
          with(:avg_impressions).greater_than(0)

          stat(:avg_impressions, :type => "mean")
          stat(:avg_impressions_hour, :type => "mean")
          stat(:avg_impressions_cost, :type => "mean")
        end
        unless search.stat_response['stats_fields']["avg_impressions_es"].nil?
          {
            avg_impressions: search.stat_response['stats_fields']["avg_impressions_es"]['mean'],
            avg_impressions_hour: search.stat_response['stats_fields']["avg_impressions_hour_es"]['mean'],
            avg_impressions_cost: search.stat_response['stats_fields']["avg_impressions_cost_es"]['mean']
          }
        end
      end
    end


end