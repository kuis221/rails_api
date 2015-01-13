class EventsCalendar
  COLORS = %w(#d3c941 #606060 #a18740 #d93f99 #a766cf
              #7e42a4 #d7a23c #6c5f3c #bfbfbf #909090)

  def group(group)
    send("grouped_by_#{group}") if respond_to?("grouped_by_#{group}")
  end

  protected


  def grouped_by_brand
    days = {}
    campaing_brands_map = {}
    start_date = DateTime.strptime(params[:start], '%s')
    end_date = DateTime.strptime(params[:end], '%s')
    custom_params = search_params.merge(start_date: nil, end_date: nil)
    search = Event.do_search(custom_params, true)
    campaign_ids = search.facet(:campaign_id).rows.map { |r| r.value.to_i }
    current_company.campaigns.where(id: campaign_ids).map do |campaign|
      campaing_brands_map[campaign.id] = campaign.associated_brand_ids
    end

    brands_scope = current_company.brands
    brands_scope = brands_scope.where(id: search_params[:brand]) unless search_params[:brand].blank?

    all_brands = campaing_brands_map.values.flatten.uniq
    brands = Hash[brands_scope.where(id: all_brands).map { |b| [b.id, b] }]

    search = Event.do_search(custom_params.merge(
        start_date: start_date.to_s(:slashes),
        end_date: end_date.to_s(:slashes),
        per_page: 3000
    ))
    search.hits.each do |hit|
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
            url: events_url('brand[]' => brand.id, 'start_date' => day.to_s(:slashes)) }
          days[day][brand.id][:count] += 1
          days[day][brand.id][:description] = "<b>#{brand.name}</b><br />#{days[day][brand.id][:count]} Events"
        end
      end
    end
    days.map { |_, bs| bs.values.sort { |a, b| a[:title] <=> b[:title] } }.flatten
  end
end