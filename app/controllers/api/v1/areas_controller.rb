module Api
  module V1
    class AreasController < Api::V1::ApiController
      inherit_resources

      skip_authorization_check only: [:index, :marques]
      skip_authorize_resource only: [:index, :marques]

      resource_description do
        short 'Areas'
        formats %w(json xml)
        error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
        error 404, 'Missing'
        error 401, 'Unauthorized access'
        error 500, 'Server crashed for some reason'
        description <<-EOS

        EOS
      end

      api :GET, '/api/v1/areas', 'Get a list of areas'
      description <<-EOS
        Returns a list of areas sorted by name. Only those areas that are accessible for the user will be returned.

        Each area item have the following attributes:

        * *id*: the area's ID
        * *name*: the area's name
      EOS
      example <<-EOS
        GET /api/v1/areas.json
        [
          {
              "id": "1",
              "name": "Albany"
          },
          {
              "id": "2",
              "name": "Arizona"
          },
          {
              "id": "3",
              "name": "Asbury Park"
          },
          ...
        ]
      EOS
      def index
        @areas = current_company.areas.active.accessible_by_user(current_company_user).order(:name)
      end


      api :GET, '/api/v1/areas/:id/cities', 'Get a list of cities for an Area'
      param :id, :number, required: true, desc: "The area's ID."
      see 'areas#index'
      description <<-EOS
        Returns a list of the valid cities for an area.

        Each city item have the following attributes:

        * *id*: the city's ID
        * *name*: the city's name
        * *state*: the city's state
        * *country*: the city's country code
      EOS
      example <<-EOS
        GET /api/v1/areas/1/cities.json
        [
            {
                "id": 5212,
                "name": "Albany",
                "state": "New York",
                "country": "US"
            }
        ]
      EOS
      def cities
        authorize! :cities, Area
        @cities = resource.cities
      end
    end
  end
end
