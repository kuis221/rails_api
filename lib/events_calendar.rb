class EventsCalendar
  COLORS = %w(#d3c941 #606060 #a18740 #d93f99 #a766cf
              #7e42a4 #d7a23c #6c5f3c #bfbfbf #909090)

  def initialize(company_user, params)
    @company_user = company_user
    @params = params.merge(
      company_id: @company_user.company_id,
      current_company_user: @company_user,
      search_permission: 'view_calendar')
  end

  def group(group)
    send("grouped_by_#{group}") if respond_to?("grouped_by_#{group}")
  end

  def grouped_by_brand
    days = {}
    campaing_brands_map = {}
    custom_params = @params.merge(start_date: nil, end_date: nil)
    search = Event.do_search(custom_params, true)
    campaign_ids = search.facet(:campaign_id).rows.map { |r| r.value.to_i }
    company.campaigns.where(id: campaign_ids).map do |campaign|
      campaing_brands_map[campaign.id] = campaign.associated_brand_ids
    end

    brands_scope = company.brands
    brands_scope = brands_scope.where(id: @params[:brand]) unless @params[:brand].blank?

    all_brands = campaing_brands_map.values.flatten.uniq
    brands = Hash[brands_scope.where(id: all_brands).map { |b| [b.id, b] }]

    search_events_for_month.hits.each do |hit|
      sd = hit.stored(:start_at).in_time_zone.to_date
      ed = hit.stored(:end_at).in_time_zone.to_date
      (sd..ed).each do |day|
        days[day] ||= {}
        next unless campaing_brands_map[hit.stored(:campaign_id).to_i]

        campaing_brands_map[hit.stored(:campaign_id).to_i].each do |brand_id|
          next unless brands.key?(brand_id)
          brand = brands[brand_id]
          days[day][brand.id] ||= {
            count: 0,
            title: brand.name,
            start: day,
            end: day,
            color: COLORS[all_brands.index(brand.id) % COLORS.count],
            url: Rails.application.routes.url_helpers.events_path('brand[]' => brand.id, 'start_date' => day.to_s(:slashes)) }
          days[day][brand.id][:count] += 1
          days[day][brand.id][:description] = "<b>#{brand.name}</b><br />#{days[day][brand.id][:count]} Events"
        end
      end
    end
    days.map { |_, bs| bs.values.sort { |a, b| a[:title] <=> b[:title] } }.flatten
  end

  def grouped_by_campaign
    days = {}
    campaign_names = Hash[Campaign.where(id: search_events_for_month.hits.map { |h| h.stored(:campaign_id) }).pluck(:id, :name)]
    campaign_ids = campaign_names.keys
    search_events_for_month.hits.each do |hit|
      sd = hit.stored(:start_at).in_time_zone.to_date
      ed = hit.stored(:end_at).in_time_zone.to_date
      campaign_id = hit.stored(:campaign_id)
      (sd..ed).each do |day|
        days[day] ||= {}
        days[day][campaign_id] ||= {
          count: 0,
          title: campaign_names[campaign_id],
          start: day,
          end: day,
          color: COLORS[campaign_ids.index(campaign_id) % COLORS.count],
          url: Rails.application.routes.url_helpers.events_path('campaign[]' => campaign_id, 'start_date' => day.to_s(:slashes)) }
        days[day][campaign_id][:count] += 1
        days[day][campaign_id][:description] = "<b>#{campaign_names[campaign_id]}</b><br />#{days[day][campaign_id][:count]} Events"
      end
    end
    days.map { |_, bs| bs.values.sort { |a, b| a[:title] <=> b[:title] } }.flatten
  end

  def grouped_by_event
    days = {}
    campaign_names = Hash[Campaign.where(id: search_events_for_month.hits.map { |h| h.stored(:campaign_id) }).pluck(:id, :name)]
    campaign_ids = campaign_names.keys
    search_events_for_month.hits.each do |hit|
      start_at = company.timezone_support? ? hit.stored(:local_start_at) : hit.stored(:start_at).in_time_zone
      day = start_at.to_date
      campaign_id = hit.stored(:campaign_id)
      key = hit.stored(:id)
      title = "#{start_at.strftime('%l%P').gsub(/([ap])m/, '\1')} #{campaign_names[campaign_id]}"
      days[day] ||= {}
      days[day][key] ||= {
        title: title,
        start: day,
        start_at: start_at,
        end: day,
        count: 1,
        description: "<b>#{campaign_names[campaign_id]}</b><br />1 Event",
        color: COLORS[campaign_ids.index(campaign_id) % COLORS.count],
        url: Rails.application.routes.url_helpers.events_path('id[]' => key) }
    end
    days.map { |_, bs| bs.values.sort { |a, b| a[:start_at] <=> b[:start_at] } }.flatten
  end

  def grouped_by_user
    days = {}
    campaign_names = Hash[Campaign.where(id: search_events_for_month.hits.map { |h| h.stored(:campaign_id) }).pluck(:id, :name)]
    campaign_ids = campaign_names.keys
    events_users = Hash.new { |hash, key| hash[key] = [] }
    company.events.joins_for_user_teams
           .where(id: search_events_for_month.hits.map { |h| h.stored(:id) } )
           .pluck('events.id, company_users.id, users.first_name || \' \' || users.last_name').each do |row|
      events_users[row[0]].push([row[1], row[2]]) if row[1]
    end
    search_events_for_month.hits.each do |hit|
      sd = hit.stored(:start_at).in_time_zone.to_date
      ed = hit.stored(:end_at).in_time_zone.to_date
      id = hit.stored(:id)
      next unless events_users.key?(id)
      (sd..ed).each do |day|
        events_users[id].each do |user|
          days[day] ||= {}
          days[day][user[1]] ||= {
            count: 0,
            title: user[1],
            start: day,
            end: day,
            color: COLORS.sample,
            url: Rails.application.routes.url_helpers.events_path('user[]' => user[0], 'start_date' => day.to_s(:slashes)) }
          days[day][user[1]][:count] += 1
          days[day][user[1]][:description] = "<b>#{user[1]}</b><br />#{days[day][user[1]][:count]} Events"
        end
      end
    end
    days.map { |_, bs| bs.values.sort { |a, b| a[:title] <=> b[:title] } }.flatten
  end

  def search_events_for_month
    return @events_search if @events_search

    start_date = DateTime.strptime(@params[:start], '%s')
    end_date = DateTime.strptime(@params[:end], '%s')
    @events_search ||= Event.do_search(@params.merge(
        start_date: start_date.to_s(:slashes),
        end_date: end_date.to_s(:slashes),
        per_page: 3000
    ))
  end

  def company
    @company_user.company
  end
end