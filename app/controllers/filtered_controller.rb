# Filtered Controller class
#
# This class in intented to be used as a base for all those
# controllers that have filtering capabilities
class FilteredController < InheritedResources::Base
  include ExportableController

  helper_method :collection_count, :collection_total_count, :facets, :page,
                :total_pages, :search_params

  respond_to :json, only: :index

  CUSTOM_VALIDATION_ACTIONS = [:index, :items, :export, :new_export]
  load_and_authorize_resource except: CUSTOM_VALIDATION_ACTIONS

  before_action :authorize_actions, only: CUSTOM_VALIDATION_ACTIONS

  custom_actions collection: [:filters, :items]

  def filters
  end

  def items
    render layout: false
  end

  def export
    @export = ListExport.find_by_id(params[:download_id])
  end

  def index
    super
  end

  protected

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    {}
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

  def collection
    get_collection_ivar || begin
      return unless action_name != 'index' || request.format.json?
      if resource_class.respond_to?(:do_search) # User Sunspot Solr for searching the collection
        @collection_count = collection_search.total
        @total_pages = collection_search.results.total_pages
        set_collection_ivar(collection_search.results)
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

  def search_params
    @search_params ||= params.permit(permitted_search_params).tap do |p|
      CustomFilter.where(id: params[:cfid]).each do |cf|
        p[:end_date] = params[:start_date] if params.key?('start_date') && !params.key?('end_date')
        p.deep_merge!(Rack::Utils.parse_nested_query(cf.filters)) do |key, v1, v2|
          if %w(start_date end_date).include?(key)
            Array(v1) + Array(v2)
          else
            (Array(v1) + Array(v2)).uniq
          end
        end
      end if params[:cfid].present?
      p.merge!(base_search_params)
    end
  end

  def base_search_params
    {
      company_id: current_company.id,
      current_company_user: current_company_user
    }
  end

  def permitted_search_params
    [:page, :sorting, :per_page, :sorting_dir].concat resource_class.searchable_params
  end

  def collection_count
    collection
    @collection_count ||= @collection_count_scope.count
  end

  def collection_total_count
    @collection_total_count ||= begin
      if resource_class.respond_to?(:do_search)
        resource_class.do_search(base_search_params).total
      else
        end_of_association_chain.accessible_by_user(current_user).count
      end
    end
  end

  def collection_search
    @solr_search ||= resource_class.do_search(search_params)
  end

  def total_pages
    @total_pages ||= (collection_count.to_f / items_per_page.to_f).ceil
  end

  def items_per_page
    30
  end

  def controller_filters(c)
    c
  end

  # Makes sure that the resource is immediate indexed.
  # this can be used in any controller with:
  #  after_action :force_resource_reindex, only: [:create]
  def force_resource_reindex
    with_immediate_indexing do
      Sunspot.index resource if resource.persisted? && resource.errors.empty?
    end
  end

  def with_immediate_indexing
    old_session = Sunspot.session
    if Sunspot.session.is_a?(Sunspot::Queue::SessionProxy)
      Sunspot.session = Sunspot.session.session
    end
    yield
    Sunspot.commit
  ensure
    Sunspot.session = old_session
  end
end
