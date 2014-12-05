module AutocompleteHelper
  # Autocomplete helper methods
  def autocomplete_buckets(list)
    search_classes = list.values.flatten
    options = items_to_show(format: :string).map(&:capitalize)

    return [] unless options.any?

    search = Sunspot.search(search_classes) do
      keywords(params[:q]) do
        fields(:name)
        highlight :name
      end
      group :class do
        limit 5
      end
      with(:company_id, [-1, current_company.id])

      search_classes.each do |klass|
        param = (klass == CompanyUser ? 'user' : klass.name.underscore)
        next unless params.key?(param)
        any_of do
          without :class, klass
          without :id, params[param]
        end
      end

      any_of do
        search_classes.each do |klass|
          all_of do
            with :class, klass
            with :status, options
          end
        end
      end
    end

    special_buckets = [:active_state, :event_status, :task_status, :user_active_state]
    list.map do |bucket_name, klasess|
      if special_buckets.include?(bucket_name)
        build_special_bucket(bucket_name, params[:q] || '')
      else
        build_bucket(search, bucket_name, klasess) if klasess.any?
      end
    end.compact
  end

  def build_special_bucket(bucket_name, q)
    type = [:active_state, :user_active_state].include?(bucket_name) ? :status : bucket_name
    results = special_buckets_options(bucket_name).select do |a|
      (params[type].blank? || !params[type].include?(a)) &&
      a.downcase.include?(q)
    end.first(5)
    { label: I18n.translate("filters.#{bucket_name}"),
      value: results.map { |x| { label: x.gsub(/(#{q})/i, '<i>\1</i>'), value: x, type: type } } }
  end

  def special_buckets_options(bucket_name)
    @_special_buckets_options ||= {
      active_state: %w(Active Inactive),
      user_active_state: %w(Active Inactive Invited),
      event_status: %w(Submitted Rejected Approved Late Due),
      task_status: %w(Complete Incomplete Late)
    }
    @_special_buckets_options[bucket_name] || []
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
end
