class Api::V1::BrandsController < Api::V1::ApiController
  inherit_resources

  skip_authorization_check only: [:index, :marques]
  skip_authorize_resource only: [:index, :marques]

  resource_description do
    short 'Brands'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/brands', "Get a list of brands"
  description <<-EOS
    Returns a list of brands sorted by name. Only those brands that are accessible for the user will be returned.

    Each brand item have the followign attributes:

    * *id*: the brand's ID
    * *name*: the brand's name
    * *active*: the brand's status
  EOS
  example <<-EOS
    GET /api/v1/brands.json?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    [
      {
          "id": "1",
          "name": "Absolut",
          "active": true
      },
      {
          "id": "2",
          "name": "Jameson LOCALS",
          "active": true
      },
      {
          "id": "3",
          "name": "Ricards",
          "active": true
      },
      ...
    ]
  EOS
  def index
    @brands = current_company.brands.active.accessible_by_user(current_company_user).order(:name)
  end

  api :GET, '/api/v1/brands/:id/marques', "Get a list of marques for a brand"
  param :id, :number, required: true, desc: "The brand's ID."
  see 'brands#index'
  description <<-EOS
    Returns a list of the valid marques for a brand.

    Each marque item have the followign attributes:

    * *id*: the marque's ID
    * *name*: the marque's name
  EOS
  example <<-EOS
    GET /api/v1/brands/1/marques.json?auth_token=XXXXXYYYYYZZZZZ&company_id=1
    [
      {
          "id": "1",
          "name": "Marque #1"
      },
      {
          "id": "2",
          "name": "Marque #2"
      },
      {
          "id": "3",
          "name": "Marque #3"
      },
      ...
    ]
  EOS
  def marques
    @marques = resource.marques
  end
end