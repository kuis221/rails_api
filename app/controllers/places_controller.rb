class PlacesController < FilteredController
  skip_authorize_resource only: [:destroy, :create, :new]

  actions :index, :new, :create
  belongs_to :area, :campaign, :company_user, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]

  def create
    @place = Place.new(place_params)
    if current_company_user.allowed_to_access_place?(@place)
      if respond_to?(:parent?)
        authorize!(:add_place, parent)
      else
        authorize!(:create, Venue)
      end
      reference_value = params[:place][:reference]

      if params[:add_new_place].present?
        if set_lat_lon_from_address(@place)
          spot = search_place_in_google_api_by_name(@place)

          # If the place was not found in API, create it
          if spot.nil?
            create_place_in_google_api(@place)
            # Save the place on the database with the user's entered data
            @place.save
          else
            reference_value = spot.reference+'||'+spot.id
          end
        else
          @place.errors.add(:base, 'The entered address doesn\'t seems to be valid')
        end
        @from_new_place_form = true
      end

      if reference_value and !reference_value.nil? and !reference_value.empty?
        if reference_value =~ /(.*)\|\|(.*)/
          reference, place_id = reference_value.split('||')
          @place = Place.find_or_create_by_place_id(place_id, {reference: reference})
        else
          @place = Place.find(reference_value)
        end

        # There can be spots that doesn't have all address
        # fields in the API, so update it as needed
        @place.city ||= params[:place][:city]
        @place.country ||= params[:place][:country]
        @place.state ||= params[:place][:state]
        @place.street_number ||= params[:place][:street_number]
        @place.route ||= params[:place][:route]
        @place.zipcode ||= params[:place][:zipcode]
        @place.save if @place.changed?
      end

      if @place.persisted?
        parent.update_attributes({place_ids: parent.place_ids + [@place.id]}, without_protection: true) if parent.present?

        # Create a Venue for this place on the current company
        @venue = Venue.find_or_create_by_company_id_and_place_id(current_company.id, @place.id)
      else
        render 'new_place'
      end
    else
      @place.errors.add(:base, 'You are not allowed to create venues on this location') if params[:add_new_place].present?
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

  private
    def place_params
      params.permit(place: [:name, :types, :street_number, :route, :city, :state, :zipcode, :country])[:place]
    end

    # Try to find the latitude and logitude based on a physicical address and returns
    # true if found or false if not
    def set_lat_lon_from_address(place)
      address_txt = URI::encode([place.street_number,
                                 place.route,
                                 place.city,
                                 place.state + ' ' + place.zipcode,
                                 place.country].join(', '))

      data = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address_txt}&sensor=true").read)
      if data['results'].count > 0
        location = data['results'].detect{|r| r['geometry'].present? && r['geometry']['location'].present?}
        if location
          place.latitude = location['lat']
          place.longitude = location['lng']
          true
        else
          false
        end
      else
        false
      end
    end

    # Search a place in google's API by name in a radius of 1km and returns
    # the spot if found or nil if not
    def search_place_in_google_api_by_name(place)
      spot = nil
      spots = api_client.spots(place.latitude, place.longitude, name: place.name, :radius => 1000)
      spot = spots.first unless spots.empty?
      spot
    end

    # Creates a new place in Google's API and returns true if success or false if an error
    # ocurred
    def create_place_in_google_api(place)
      address = {
        :location => {
          :lat => place.latitude,
          :lng => place.longitude
        },
        :accuracy => 50,
        :name => place.name,
        :types => [place.types]
      }
      result = HTTParty.post("https://maps.googleapis.com/maps/api/place/add/json?sensor=true&key=#{GOOGLE_API_KEY}",
                              :body => address.to_json,
                              :headers => { 'Content-Type' => 'application/json' }
                            )
      if result['reference'].present? && result['id'].present?
        place.reference = result['reference']
        place.place_id = result['id']
        true
      else
        false
      end
    end

    # Returns a cached API client
    def api_client
      @api_client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end
end
