class PlacesController < FilteredController
  include PlacesHelper::CreatePlace

  skip_authorize_resource only: [:destroy, :create, :new]

  actions :index, :new, :create
  belongs_to :area, :campaign, :company_user, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]

  def create
    unless create_place(place_params, params[:add_new_place].present?)
      render 'new_place'
    end
  end

  def destroy
    authorize!(:remove_place, parent)

    @place = Place.find(params[:id])
    parent.places.destroy(@place)
  end

  def search
    location = params[:location] || location_from_request
    ignore_permissions = params[:check_valid] == 'false'
    options = { company_id: current_company.id,
                q: params[:term], location: location, search_address: true }
    options.merge!(current_company_user: current_company_user) unless ignore_permissions
    results = Place.combined_search options
    render json: results
  end

  protected

  def place_params
    params.permit(place: [:name, :types, :street_number, :route, :city, :state, :zipcode, :country, :reference])[:place]
  end

  def location_from_request
    location = request.location
    return if location.nil? || location.latitude == 0.0
    "#{location.latitude},#{location.longitude}"
  end
end
