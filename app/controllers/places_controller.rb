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
    params.permit(place: [
      :name, :types, :street_number, :route, :city, :state, :zipcode, :country, :reference,
      venues_attributes: [:company_id, results_attributes: [:id, :value, :form_field_id]]
    ])[:place].tap do |whielisted|
      unless whielisted.nil? || whielisted[:venues_attributes].nil?
        whielisted[:venues_attributes].each do |vk, venue_attrs|
          next if venue_attrs[:results_attributes].nil?
          venue_attrs[:results_attributes].each do |k, value|
            value[:value] = params[:place][:venues_attributes][vk][:results_attributes][k][:value]
          end
        end
      end
    end
  end

  def location_from_request
    location = request.location
    return if location.nil? || location.latitude == 0.0
    "#{location.latitude},#{location.longitude}"
  end
end
