module AutocompleteHelper
  # Autocomplete helper methods
  def autocomplete_buckets(list)
    search_classes = list.values.flatten
    search = Sunspot.search(search_classes) do
      keywords(params[:q]) do
        fields(:name)
        highlight :name
      end
      group :class do
        limit 5
      end
      with(:company_id, [-1, current_company.id])
      with(:status, ['Active'])
    end

    @autocomplete_buckets ||= list.map do |bucket_name, klasess|
      build_bucket(search, bucket_name, klasess)
    end
  end

  def build_bucket(search, bucket_name, klasess)
    results = []
    search.group(:class).groups.each do |group|
      results += group.hits if klasess.include? group.value.constantize
    end

    # Sort by scoring if we are grouping multiple clasess into one bucket
    results = results.sort{|a, b| b.score <=> a.score }.first(5) if klasess.size > 1
    {label: bucket_name.to_s.gsub(/[_]+/, ' ').capitalize, value: get_bucket_results(results)}
  end

  def get_bucket_results(results)
    results.map{|x| {label: (x.highlight(:name).nil? ? x.stored(:name) : x.highlight(:name).format{|word| "<i>#{word}</i>" }), value: x.primary_key, type: x.class_name.underscore.downcase} }
  end
end
