class FilteredController < InheritedResources::Base
  helper_method :collection_count, :facets, :page, :total_pages
  respond_to :json, only: :index

  load_and_authorize_resource except: [:index, :items, :filters, :autocomplete]

  custom_actions collection: [:filters, :items]

  after_filter :set_xlsx_header, only: :index

  def filters
  end

  def items
    render layout: false
  end

  protected

    def set_xlsx_header
      response.headers['Content-Disposition'] = "attachment; filename=\"#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}.xlsx\"" if request.format.xlsx?
    end

    def collection
      get_collection_ivar || begin
        if action_name != 'index' || request.format.json? || request.format.xlsx?
          if resource_class.respond_to?(:do_search) # User Sunspot Solr for searching the collection
            search = resource_class.do_search(search_params)
            @collection_count = search.total
            @total_pages = search.results.total_pages
            set_collection_ivar(search.results)
          else
            current_page = params[:page] || nil
            c = end_of_association_chain.accessible_by(current_ability).scoped(sorting_options)
            c = controller_filters(c)
            @collection_count_scope = c
            c = c.page(current_page).per(items_per_page) unless current_page.nil?
            set_collection_ivar(c.respond_to?(:scoped) ? c.scoped : c.all)
          end
        end
      end
    end

    def collection_count
      collection
      @collection_count ||= @collection_count_scope.count
    end

    def total_pages
      @total_pages ||= (collection_count.to_f/items_per_page.to_f).ceil
    end

    def facets
      @facets ||= []
    end

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
        any_of do
          # The actual class should also include inactive results
          with(:class, resource_class) if search_classes.include?(resource_class)
          with(:status, ['Active'])
        end
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
      results = results.sort { |a, b| b.score <=> a.score }.first(5) if klasess.size > 1
      {label: bucket_name.to_s.gsub(/[_]+/, ' ').capitalize, value: get_bucket_results(results)}
    end

    def get_bucket_results(results)
      results.map{|x| {label: (x.highlight(:name).nil? ? x.stored(:name) : x.highlight(:name).format{|word| "<i>#{word}</i>" }), value: x.primary_key, type: x.class_name.underscore.downcase} }
    end

    def build_facet_item(options)
      options[:selected] ||= params.has_key?(options[:name]) && ((params[options[:name]].is_a?(Array) and params[options[:name]].include?(options[:id])) || (params[options[:name]] == options[:id]))
      options
    end

    def search_params
      @search_params ||= params.dup.tap do |p|  # Duplicate the params array to make some modifications
        p[:company_id] = current_company.id
        if request.format.xlsx?
          p[:per_page] = 20000
        end
      end
    end


    def build_brands_bucket(campaings)
      campaigns_counts = Hash[campaings.map{|x| id, name = x.value.split('||'); [id.to_i, x.count] }]
      brands = {}
      Campaign.includes(:brands).where(id: campaigns_counts.keys).each do |campaign|
        campaing_brands = Hash[campaign.brands.map{|b| [b.id, {label: b.name, id: b.id, name: :brand, count: campaigns_counts[campaign.id]}] }]
        brands.merge!(campaing_brands){|k,a1,a2|  a1.merge({count: (a1[:count] + a2[:count])}) }
      end
      brands = brands.values.sort{|a, b| b[:count] <=> a[:count] }
      {label: 'Brands', items: brands}
    end

    def build_locations_bucket(facets)
      first_five = facets.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: Base64.strict_encode64(x.value), count: x.count, name: :place}) }.first(5)
      first_five_ids = first_five.map{|x| x[:id] }
      locations = {}
      locations = Place.where(id: facets.map{|x| x.value.split('||')[0]}.uniq.reject{|id| first_five_ids.include?(id) }).load_organized(current_company.id)

      {label: 'Locations', top_items: first_five, items: locations}
    end

    def items_per_page
      30
    end

    def controller_filters(c)
      c
    end

    def sorting_options
      if params.has_key?(:sorting) &&  sort_options[params[:sorting]] && params[:sorting_dir]
        options = sort_options[params[:sorting]].dup
        options[:order] = options[:order] + ' ' + params[:sorting_dir] if sort_options.has_key?(params[:sorting])
        options
      end
    end

    def sort_options
      {}
    end
end