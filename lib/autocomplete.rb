class Autocomplete
  attr_accessor :scope
  attr_accessor :user
  attr_accessor :params

  SETTINGS = YAML.load_file(File.join(Rails.root, 'config', 'autocomplete.yml')).tap do |settings|
    settings['autocomplete'].each do |_collection, config|
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

  def search
    return [] if SETTINGS['autocomplete'][scope].nil?
    autocomplete_buckets SETTINGS['autocomplete'][scope]
  end

  protected

  # Autocomplete helper methods
  def autocomplete_buckets(list)
    search_classes = list.values.map{ |c| c['classes'] }.flatten.compact
    options = items_to_show(format: :string).map(&:capitalize)

    return [] unless options.any?

    if search_classes.any?
      search = Sunspot.search(search_classes) do
        keywords(params[:q]) do
          fields(:name)
          highlight :name
        end
        group :class do
          limit 5
        end
        with(:company_id, [-1, user.company_id])

        search_classes.each do |klass|
          param = (klass == CompanyUser ? 'user' : klass.name.underscore)
          next unless params.key?(param)
          any_of do
            without :class, klass
            without :id, params[param]
          end
        end

        if search_classes.include?(Campaign)
          any_of do
            without :class, Campaign
            with :id, user.accessible_campaign_ids
          end
        end

        with :status, options
      end
    end

    list.map do |bucket_name, config|
      if config['items'].present? && config['items'].any?
        build_special_bucket(bucket_name, config['items'], params[:q] || '')
      elsif search_classes.any? && config['classes'].present?
        build_bucket(search, bucket_name, config['classes']) if config['classes'].any?
      end
    end.compact
  end

  def build_special_bucket(bucket_name, options, q)
    value = options.select do |opt|
      a = opt.is_a?(Array) ? opt[0].to_s : opt
      (params[bucket_name].blank? || !params[bucket_name].include?(a)) &&
      a.downcase.include?(q)
    end.first(5).map do |opt|
      if opt.is_a?(Array)
        { label: opt[1].gsub(/(#{q})/i, '<i>\1</i>'), value: opt[0], type: bucket_name }
      else
        { label: opt.gsub(/(#{q})/i, '<i>\1</i>'), value: opt, type: bucket_name }
      end
    end

    { label: I18n.translate("filters.#{bucket_name}"),
      value:  value}
  end

  def build_bucket(search, bucket_name, klasess)
    results = []
    search.group(:class).groups.each do |group|
      results += group.hits if klasess.include? group.value.constantize
    end

    # Sort by scoring if we are grouping multiple clasess into one bucket
    results = results.sort { |a, b| b.score <=> a.score }.first(5) if klasess.size > 1
    { label: I18n.translate("filters.#{bucket_name}"), value: get_bucket_results(results) }
  end

  def get_bucket_results(results)
    results.map do |x|
      {
        label: (x.highlight(:name).nil? ? x.stored(:name) : x.highlight(:name).format { |word| "<i>#{word}</i>" }),
        value: x.primary_key, type: (x.class_name == 'CompanyUser' ? 'user' : x.class_name.underscore)
      }
    end
  end

  def autocomplete_filter_settings_scope
    params[:apply_to] || controller_name
  end

  def items_to_show(format: :boolean)
    if format == :string
      user.filter_setting_present('show_inactive_items', scope) ? ['active', 'inactive'] : ['active']
    else
      user.filter_setting_present('show_inactive_items', scope) ? [true, false] : [true]
    end
  end
end
