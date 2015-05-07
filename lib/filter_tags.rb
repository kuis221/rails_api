# Class used to generate the filter tags given the current
# params

class FilterTags
  attr_accessor :params, :company_user, :company, :builder_block

  def initialize(params, company_user)
    self.params = params
    self.company_user = company_user
    self.company = company_user.company
  end

  def tags(&block)
    self.builder_block = block
    (describe_status + describe_prices + describe_custom_date_ranges +
     describe_brands + describe_brand_portfolios + describe_campaigns +
     describe_areas + describe_places + describe_venues + describe_cities + describe_users +
     describe_teams + describe_roles + describe_activity_types + describe_date_ranges +
     describe_day_parts + describe_tasks + describe_range_filters + describe_tags +
     describe_rating + describe_custom_filters).reject(&:empty?).compact
  end

  def describe_custom_date_ranges
    params[:start_date] = Array(params[:start_date])
    params[:end_date] = Array(params[:end_date])

    dates_descriptions = []
    params[:start_date].each_with_index do |start_date, index|
      start_date = start_date.blank? ? nil : start_date
      end_date = params[:end_date][index].blank? ? nil : params[:end_date][index]
      dates_descriptions.push describe_custom_date_range(start_date, end_date)
    end
    dates_descriptions
  end

  def describe_custom_date_range(start_date, end_date)
    return [] if start_date.nil?
    dates = [start_date, end_date == start_date ? nil : end_date].compact.map { |d| Timeliness.parse(d).to_date }.map do |d|
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
        dates.map { |d| d.is_a?(Date) ? d.to_s(:simple_short) : d }.join(' - ')
      end

    build_filter_object_item dates, "date:#{start_date},#{end_date}", expandible: false
  end

  def describe_range_filters
    params.select { |_k, v| v.is_a?(Hash) && v.key?(:max) && v.key?(:min) }.map do |k, v|
      build_filter_object_item "#{I18n.t('range_filters.' + k.to_s)} between #{v[:min]} and #{v[:max]}", k
    end
  end

  def describe_campaigns
    describe_resource_params(:campaign,
                             company.campaigns.order('campaigns.name ASC'))
  end

  def describe_areas
    describe_resource_params(:area,
                             company.areas.order('areas.name ASC'),
                             expandible: true)
  end

  def describe_tasks
    describe_resource_params(:task,
                             Task.by_companies(company).order('tasks.title ASC'), label_attribute: :title)
  end

  def describe_activity_types
    describe_resource_params(:activity_type,
                             company.activity_types.order('activity_types.name ASC'))
  end

  def describe_date_ranges
    describe_resource_params(:date_range,
                             company.date_ranges.order('date_ranges.name ASC'))
  end

  def describe_day_parts
    describe_resource_params(:day_part,
                             company.day_parts.order('day_parts.name ASC'))
  end

  def describe_brands
    describe_resource_params(:brand,
                             company.brands.order('brands.name ASC'))
  end

  def describe_places
    describe_resource_params(:place,
                             Place.order('places.name ASC'))
  end

  def describe_brand_portfolios
    describe_resource_params(:brand_portfolio,
                             company.brand_portfolios.order('brand_portfolios.name ASC'),
                             expandible: true)
  end

  def describe_cities
    build_filter_object_list :city, filter_params(:city).map { |city| [city, city] }
  end

  def describe_prices
    prices = {
      '1' => '$',
      '2' => '$$',
      '3' => '$$$',
      '4' => '$$$$'
    }
    build_filter_object_list :price, filter_params(:price).map { |price| [price, prices[price]] }
  end

  def describe_venues
    describe_resource_params(:venue,
                             company.venues.joins(:place).order('places.name ASC'))
  end

  def describe_users
    describe_resource_params(
      :user,
      company.company_users.joins(:user).order('2 ASC'),
      label_attribute: 'users.first_name || \' \' || users.last_name as name')
  end

  def describe_teams
    describe_resource_params(:team,
                             company.teams.order('teams.name ASC'),
                             expandible: true)
  end

  def describe_roles
    describe_resource_params(:role,
                             company.roles.order('roles.name ASC'))
  end

  def describe_status
    status = filter_params(:status).sort
    event_status = filter_params(:event_status).sort
    task_status = filter_params(:task_status).sort
    [
      build_filter_object_list(:status, status.map { |status| [status, status] }),
      build_filter_object_list(:event_status, event_status.map { |status| [status, status] }),
      build_filter_object_list(:task_status, task_status.map { |status| [status, status] })
    ].compact
  end

  def describe_tags
    describe_resource_params(:tag,
                             company.tags.order('tags.name ASC'))
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
    build_filter_object_list :rating, filter_params(:rating).map { |rating| [rating, ratings[rating]] }
  end

  def describe_custom_filters
    custom_filter = CustomFilter.for_company_user(company_user)
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
    return [] unless ids.size > 0
    build_filter_object_list param_name,
                             base_scope.where(id: ids).pluck(:id, label_attribute),
                             expandible: expandible
  end

  def build_filter_object_list(filter_name, list, expandible: false)
    return [] if list.blank?
    list.map do |item|
      build_filter_object_item item[1], "#{filter_name}:#{item[0]}", expandible: expandible
    end
  end

  def build_filter_object_item(label, filter_name, expandible: false)
    if builder_block
      builder_block.call(label, filter_name, expandible)
    else
      { label: label, name: filter_name, expandible: expandible }
    end
  end
end