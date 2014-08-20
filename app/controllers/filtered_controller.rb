class FilteredController < InheritedResources::Base
  include FacetsHelper
  include AutocompleteHelper

  helper_method :collection_count, :facets, :page, :total_pages, :each_collection_item, :return_path
  respond_to :json, only: :index

  CUSTOM_VALIDATION_ACTIONS = [:index, :items, :filters, :autocomplete, :export, :new_export]
  load_and_authorize_resource except: CUSTOM_VALIDATION_ACTIONS

  before_filter :authorize_actions, only: CUSTOM_VALIDATION_ACTIONS

  after_filter :remove_resource_new_notifications, only: :show

  custom_actions collection: [:filters, :items]

  def return_path
    url_to_return = params[:return] || request.env['HTTP_REFERER']
    url_to_return if url_valid? url_to_return
  end

  def filters
  end

  def items
    render layout: false
  end

  def export
    @export = ListExport.find_by_id(params[:download_id])
  end

  def index
    if request.format.xls?
      @export = ListExport.create(controller: self.class.name,  params: search_params, export_format: 'xls', company_user: current_company_user)
      if @export.new?
        @export.queue!
      end
      render action: :new_export, formats: [:js]
    else
      super
    end
  end

  protected
    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      {}
    end

    alias_method :devise_current_user, :current_user
    def current_user
      @_current_user ||= devise_current_user
    end

    def authorize_actions
      if parent?
        authorize! "index_#{resource_class.to_s.pluralize.downcase}", parent
      else
        authorize! :index, resource_class
      end
    end

    def action_permissions

    end

    def export_list(export)
      @_export = export
      @search_params = export.params.merge(per_page: 100)
      @solr_search = resource_class.do_search(@search_params)
      @collection_count = @solr_search.total
      @total_pages = @solr_search.results.total_pages
      @collection_results = @solr_search.results
      set_collection_ivar(@solr_search.results)

      Slim::Engine.with_options(pretty: true, sort_attrs: false, streaming: false) do
        render_to_string :index, handlers: [:slim], formats: [:xls], layout: false
      end
    end

    def each_collection_item
      p = @search_params.dup
      (1..@total_pages).each do |page|
        p[:page] = page
        search = resource_class.do_search(p)
        search.results.each do |result|
          yield result
        end
        @_export.update_column(:progress, (page*100/@total_pages).round) unless @_export.nil?
      end
    end

    def export_file_name
      "#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
    end

    def collection
      get_collection_ivar || begin
        if action_name != 'index' || request.format.json?
          if resource_class.respond_to?(:do_search) # User Sunspot Solr for searching the collection
            @solr_search = resource_class.do_search(search_params)
            @collection_count = @solr_search.total
            @total_pages = @solr_search.results.total_pages
            set_collection_ivar(@solr_search.results)
          else
            current_page = params[:page] || nil
            c = end_of_association_chain.accessible_by_user(current_user)
            c = controller_filters(c)
            @collection_count_scope = c
            c = c.page(current_page).per(items_per_page) unless current_page.nil?
            set_collection_ivar(c)
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

    def items_per_page
      30
    end

    def controller_filters(c)
      c
    end

    # Makes sure that the resource is immediate indexed.
    # this can be used in any controller with:
    #  after_index :force_resource_reindex, only: [:create]
    def force_resource_reindex
      with_immediate_indexing do
        Sunspot.index resource if resource.persisted? && resource.errors.empty?
      end
    end

    def remove_resource_new_notifications
      case resource.class.name
      when "Event"
        #Remove the notifications related to new events (including for teams) and keep the notifications for new tasks associated to the event and user
        current_company_user.notifications.where("message = 'new_event' OR message = 'new_team_event'").where("params->'event_id' = (?)", resource.id.to_s).destroy_all
      when "Campaign"
        current_company_user.notifications.new_campaigns.where("params->'campaign_id' = (?)", resource.id.to_s).destroy_all
      end
    end
end