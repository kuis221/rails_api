# This module defines the do_search method and uses the helper methods
# defined in lib/solr_extensions.rb for filtering by campaign/area/etc
# TODO: we will probably want to

module SolrSearchable
  extend ActiveSupport::Concern

  module ClassMethods
    def build_solr_search(params)
      clazz = self
      Sunspot.new_search(self) do
        self_param_name = (clazz.name == 'CompanyUser' ? :user : clazz.name.underscore.to_sym)
        with :company_id, params[:company_id]
        with_id params.delete(self_param_name) if params[self_param_name]
        with_campaign params[:campaign] if params[:campaign]
        with_area params[:area], params[:campaign] if params[:area]
        with_place params[:place] if params[:place]
        with_location params[:location] if params[:location]
        with_status params[:status] if params[:status]
        with_id params[:id] if params[:id]
        with_brand params[:brand] if params[:brand]
        with_brand_portfolio params[:brand_portfolio] if params[:brand_portfolio]
        with_venue params[:venue] if params[:venue]
        with_event_status params[:event_status] if params[:event_status]
        with_role params[:role] if params[:role]

        between_date_range clazz, params[:start_date], params[:end_date]

        with_user_teams params

        order_by(params[:sorting], params[:sorting_dir] || :asc) if params[:sorting]
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def do_search(params, include_facets = false, includes: nil, &block)
      search = build_solr_search(params)
      search.build(&block) if block
      search.build(&search_facets) if include_facets && respond_to?(:search_facets, true)
      if params[:current_company_user] && respond_to?(:apply_user_permissions_to_search, true)
        search.build(&apply_user_permissions_to_search((params[:search_permission_class] || self),
                                                       params[:search_permission],
                                                       params[:current_company_user]))
      end
      solr_execute_search(include: includes) do
        search
      end
    end
  end
end
