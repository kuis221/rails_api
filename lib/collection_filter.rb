class CollectionFilter
  attr_accessor :scope
  attr_accessor :user
  attr_accessor :params

  SETTINGS = YAML.load_file(File.join(Rails.root, 'config', 'filters.yml')).tap do |settings|
    settings['filters'].each do |_collection, config|
      config.each do |bucket, info|
        if info.is_a?(Array)
          config[bucket] = {
            'classes' => info.map(&:constantize),
            'label' => I18n.translate("filters.#{bucket}") }
        elsif info.is_a?(Hash)
          config[bucket]['label'] ||= I18n.translate("filters.#{bucket}")
        end
      end
    end
  end

  def initialize(scope, user, params)
    @scope = scope
    @user = user
    @params = params
  end

  def filters
    result = company_custom_filters
    return result if SETTINGS['filters'][scope].nil?
    result.concat(
      SETTINGS['filters'][scope].map do |_bucket_name, bucket_config|
        build_filter_bucket bucket_config
      end.flatten.append(user_saved_filters)
    )
  end

  def items_to_show(format: :boolean)
    if format == :string
      user.filter_setting_present('show_inactive_items', scope) ? ['active', 'inactive'] : ['active']
    else
      user.filter_setting_present('show_inactive_items', scope) ? [true, false] : [true]
    end

  def expand(type, id)
    type.classify.constantize.find(id).filter_subitems.map do |item|
      {
        id: item[0],
        name: item[1],
        type: item[2]
      }
    end
  end

  private

  def build_filter_bucket(config)
    if config.key?('method')
      send(config['method'])
    else
      { label: config['label'], items: filter_items_for(config) }
    end
  end

  def build_slider_bucket(name, config)
    { label: config[:label],
      name: name,
      min: config[:min],
      max: config[:max] > config[:min] ? config[:max] : config[:min] + 1,
      selected_min: params[name].try(:[], :min),
      selected_max: params[name].try(:[], :max) }
  end

  def filter_items_for(config)
    if config.key?('items') && config['items'].any?
      config['items'].map do |item|
        (id, label) = (item.is_a?(Array) ? [item[0], item[1]] : [item, item])
        build_filter_item(id: id, label: label, value: id, name: config['name'])
      end
    else
      filter_items_from_clasess config['classes']
    end
  end

  def venues_sliders
    facet_search = Venue.do_search({ current_company_user: user, company_id: user.company_id }, true)
    rows = facet_search.stats.first.rows
    return unless rows
    max_events       = rows.find { |r| r.stat_field == 'events_count_is' }.try(:value).try(:to_i) || 1
    max_promo_hours  = rows.find { |r| r.stat_field == 'promo_hours_es' }.try(:value).try(:to_i) || 1
    max_impressions  = rows.find { |r| r.stat_field == 'impressions_is' }.try(:value).try(:to_i) || 1
    max_interactions = rows.find { |r| r.stat_field == 'interactions_is' }.try(:value).try(:to_i) || 1
    max_sampled      = rows.find { |r| r.stat_field == 'sampled_is' }.try(:value).try(:to_i) || 1
    max_spent        = rows.find { |r| r.stat_field == 'spent_es' }.try(:value).try(:to_i) || 1
    max_venue_score  = rows.find { |r| r.stat_field == 'venue_score_is' }.try(:value).try(:to_i) || 1

    [].tap do |f|
      f.push(build_slider_bucket :events_count, label: 'Events',  min: 0, max: max_events)
      f.push(build_slider_bucket :impressions, label: 'Impressions',  min: 0, max: max_impressions)
      f.push(build_slider_bucket :interactions, label: 'Interactions',  min: 0, max: max_interactions)
      f.push(build_slider_bucket :promo_hours, label: 'Promo Hours',  min: 0, max: max_promo_hours)
      f.push(build_slider_bucket :sampled, label: 'Samples',  min: 0, max: max_sampled)
      f.push(build_slider_bucket :venue_score, label: 'Venue Score',  min: 0, max: max_venue_score)
      f.push(build_slider_bucket :spent, label: '$ Spent',  min: 0, max: max_spent)
    end
  end

  def cities_bucket
    cities = user.company.brand_ambassadors_visits
      .active.where.not(city: '').reorder(:city).pluck('DISTINCT brand_ambassadors_visits.city').map do |r|
      build_filter_item(label: r, id: r, name: :city, count: 1)
    end
    { label: 'Cities', items: cities }
  end

  def brand_ambassadors_bucket
    users = brand_ambassadors_users.where('company_users.active in (?)', items_to_show)
      .joins(:user).order('2 ASC')
      .pluck('company_users.id, users.first_name || \' \' || users.last_name as name').map do |r|
      build_filter_item(label: r[1], id: r[0], name: :user, count: 1)
    end
    { label: 'Brand Ambassadors', items: users }
  end

  def brand_ambassadors_users
    @brand_ambassadors_users ||= begin
      s = CompanyUser.accessible_by_user(user).active
      s = s.where(role_id: user.company.brand_ambassadors_role_ids) if user.company.brand_ambassadors_role_ids.any?
      s
    end
  end

  def filter_items_from_clasess(classes)
    [].tap do |items|
      classes.each do |klass|
        filter_name = klass == CompanyUser ? 'user' : klass.name.underscore
        items.concat(klass_filter_scope(klass).map do |item|
          build_filter_item(id: item[0], label: item[1], value: item[0], name: filter_name)
        end)
      end
    end
  end

  def user_saved_filters
    items = CustomFilter.for_company_user(user).user_saved_filters
            .order('custom_filters.name ASC').by_type(scope)

    { label: CustomFilter::SAVED_FILTERS_NAME,
      items: items.map do |cf|
        build_filter_item(id: cf.filters + '&id=' + cf.id.to_s,
                         label: cf.name, name: :custom_filter, count: 1)
      end }
  end

  def company_custom_filters
    groups = {}
    CustomFilter.for_company_user(user).not_user_saved_filters
      .order('custom_filters.name ASC').by_type(scope).each do |filter|
      groups[filter.group.upcase] ||= []
      groups[filter.group.upcase].push filter
    end

    groups.map do |group, filters|
      { label: group,
        items: filters.map do |cf|
          build_filter_item(id: cf.filters + '&id=' + cf.id.to_s,
                           label: cf.name, name: :custom_filter, count: 1)
        end }
    end
  end

  def klass_filter_scope(klass)
    if klass.respond_to?(:filters_scope)
      klass.accessible_by_user(user).filters_scope(self)
    else
      klass.accessible_by_user(user).order(:name).pluck(:id, :name)
    end
  end

  def build_filter_item(options)
    options[:selected] ||=
      params.key?(options[:name]) &&
      (
        (params[options[:name]].is_a?(Array) &&
         (params[options[:name]].include?(options[:id]) || params[options[:name]].include?(options[:id].to_s))) ||
        (params[options[:name]] == options[:id]) || (params[options[:name]] == options[:id].to_s)
      )
    options
  end
end
