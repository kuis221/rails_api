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
    results = Place.combined_search(company_id: current_company.id, q: params[:term], search_address: true)

    render json: results
  end

  protected
    def place_params
      params.permit(place: [:name, :types, :street_number, :route, :city, :state, :zipcode, :country, :reference])[:place]
    end
end
