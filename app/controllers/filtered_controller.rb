class FilteredController < InheritedResources::Base
    helper_method :collection_count, :collection_to_json, :facets, :page, :total_pages
    respond_to :json, only: :index
    before_filter :collection, only: :index

    def collection
      unless request.format.html?
        get_collection_ivar || begin
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
      @collection_count ||= @collection_count_scope.count
    end

    def total_pages
      @total_pages ||= (collection_count.to_f/items_per_page.to_f).ceil
    end

    def facets
    end

    def search_params
      @search_params ||= params.dup.tap do |p|  # Duplicate the params array to make some modifications
        p[:company_id] = current_company.id
      end
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

    def collection_to_json
      []
    end
end