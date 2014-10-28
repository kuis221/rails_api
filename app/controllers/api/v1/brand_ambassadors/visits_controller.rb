module Api
  module V1
    module BrandAmbassadors
      class VisitsController < Api::V1::FilteredController

        defaults resource_class: ::BrandAmbassadors::Visit

        load_and_authorize_resource only: [:show, :edit, :update, :destroy],
                                    class: ::BrandAmbassadors::Visit

        authorize_resource only: [:create, :index],
                           class: ::BrandAmbassadors::Visit

        resource_description do
          short 'Visits'
          formats %w(json xml)
          error 401, 'Unauthorized access'
          error 404, 'The requested resource was not found'
          error 406, 'The server cannot return data in the requested format'
          error 422, 'Unprocessable Entity: The change could not be processed because of errors on the data'
          error 500, 'Server crashed for some reason. Possible because of missing required params or wrong parameters'
          description <<-EOS

          EOS
        end

        api :GET, '/api/v1/brand_ambassadors/visits', 'Search for a list of visits'
        param :start_date, String, desc: 'A date to filter the visit list. When provided a start_date without an +end_date+, the result will only include visits that happen on this day. The date should be in the format MM/DD/YYYY.'
        param :end_date, String, desc: 'A date to filter the visit list. This should be provided together with the +start_date+ param and when provided will filter the list with those visits that are between that range. The date should be in the format MM/DD/YYYY.'
        param :campaign, Array, desc: 'A list of campaign ids to filter the results'
        param :page, :number, desc: 'The number of the page, Default: 1'
        def index
          collection
        end


        protected

        def permitted_search_params
          params.permit(:page, :start_date, :end_date, {campaign: []})
        end

        def skip_default_validation
          true
        end

      end
    end
  end
end