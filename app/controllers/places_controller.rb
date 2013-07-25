class PlacesController < FilteredController
  actions :index, :new, :create, :show
  belongs_to :area, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]


  def create
    reference_value = params[:place][:reference]
    if reference_value and !reference_value.nil? and !reference_value.empty?
      reference, place_id = reference_value.split('||')
      @place = Place.find_or_create_by_place_id(place_id, {reference: reference})
      parent.update_attributes({place_ids: parent.place_ids + [@place.id]}, without_protection: true)
    end
  end

  def destroy
    @place = Place.find(params[:id])
    parent.places.delete(@place)
  end


  private
    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:types) && !@search_params[:types].empty?
          @search_params[:types] = %w(establishment)
        end
        @search_params
      end
    end
end
