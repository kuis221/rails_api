module AutocompleteHelper
  # Autocomplete helper methods
  def autocomplete_buckets(list)
    search_classes = list.values.flatten
    search_classes_options = {}
    filter_settings = current_company_user.filter_settings.find_or_initialize_by(apply_to: autocomplete_filter_settings_scope)
    search_classes.each do |klass|
      options = filter_settings.filter_settings_for(klass, format: :string)
      if options.nil?
        search_classes_options[klass] = ['Active']
      elsif options.any?
        search_classes_options[klass] = options.map(&:capitalize)
      end
    end

    return [] unless search_classes_options.any?

    search = Sunspot.search(search_classes_options.keys) do
      keywords(params[:q]) do
        fields(:name)
        highlight :name
      end
      group :class do
        limit 5
      end
      with(:company_id, [-1, current_company.id])

      any_of do
        search_classes_options.each do |klass, options|
          all_of do
            with :class, klass
            with :status, options
          end
        end
      end
    end

    @autocomplete_buckets ||= list.map do |bucket_name, klasess|
      included_klasses = klasess.select { |k| search_classes_options.key?(k) }
      build_bucket(search, bucket_name, included_klasses) if included_klasses.any?
    end.compact
  end

  def build_bucket(search, bucket_name, klasess)
    results = []
    search.group(:class).groups.each do |group|
      results += group.hits if klasess.include? group.value.constantize
    end

    # Sort by scoring if we are grouping multiple clasess into one bucket
    results = results.sort { |a, b| b.score <=> a.score }.first(5) if klasess.size > 1
    { label: bucket_name.to_s.gsub(/[_]+/, ' ').capitalize, value: get_bucket_results(results) }
  end

  def get_bucket_results(results)
    results.map do |x|
      {
        label: (x.highlight(:name).nil? ? x.stored(:name) : x.highlight(:name).format { |word| "<i>#{word}</i>" }),
        value: x.primary_key, type: x.class_name.underscore.downcase
      }
    end
  end

  def autocomplete_filter_settings_scope
    params[:apply_to] || controller_name
  end
end
