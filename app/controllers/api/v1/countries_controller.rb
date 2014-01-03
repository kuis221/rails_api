class Api::V1::CountriesController < Api::V1::ApiController
  resource_description do
    short 'Countries'
    formats ['json', 'xml']
    error 404, "Missing"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
  end

  api :GET, '/api/v1/countries', "Get a list of countries"
  description <<-EOS
    Returns a list of the valid countries in the app. Useful to generate dropdowns.

    The list consist on the following attributes:
    * *id*: the coutry's code
    * *name*: the coutry's name
  EOS
  example <<-EOS
    GET /api/v1/countries.json?auth_token=XXXXXYYYYYZZZZZ
    [
      {
          "id": "AD",
          "name": "Andorra"
      },
      {
          "id": "AE",
          "name": "United Arab Emirates"
      },
      {
          "id": "AF",
          "name": "Afghanistan"
      },
      {
          "id": "AG",
          "name": "Antigua and Barbuda"
      },
      ...
    ]
  EOS
  def index
    countries = Country.all.map{|c| {id: c[1], name: c[0]}}
    respond_to do |format|
      format.json {
        render :status => 200,
               :json => countries
      }
      format.xml {
        render :status => 200,
               :xml => countries.to_xml(root: 'countries')
      }
    end
  end

  api :GET, '/api/v1/countries/:id/states', "Get a list of countries"
  param :id, String, required: true, desc: "The country's code."
  see 'countries#index'
  description <<-EOS
    Returns a list of the valid states for a country.

    The list consist on the following attributes:
    * *id*: the state's code
    * *name*: the state's name
  EOS
  example <<-EOS
    GET /api/v1/countries/US/states.json?auth_token=XXXXXYYYYYZZZZZ
    [
      {
          "id": "AK",
          "name": "Alaska"
      },
      {
          "id": "AL",
          "name": "Alabama"
      },
      {
          "id": "AR",
          "name": "Arkansas"
      },
      {
          "id": "AS",
          "name": "American Samoa"
      },
      ...
    ]
  EOS
  def states
    country = Country.new(params[:id])
    states = []
    states = country.states.map{|k,v| {id: k, name: v['name']} } if country
    respond_to do |format|
      format.json {
        render :status => 200,
               :json => states
      }
      format.xml {
        render :status => 200,
               :xml => states.to_xml(root: 'states')
      }
    end
  end
end