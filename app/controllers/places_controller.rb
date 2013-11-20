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
      automatically_created = true

      if params[:add_new_place].present?
        address_txt = URI::encode([params[:place][:street_number],
                                   params[:place][:route],
                                   params[:place][:city],
                                   params[:place][:state] + ' ' + params[:place][:zipcode],
                                   params[:place][:country]].join(', '))

        data = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address_txt}&sensor=true").read)
        if data['results'].count > 0
          latitude = data['results'].first['geometry']['location']['lat']
          longitude = data['results'].first['geometry']['location']['lng']
          if latitude.present? && longitude.present?
            api_client = GooglePlaces::Client.new(GOOGLE_API_KEY)
            spots = api_client.spots(latitude, longitude, name: "#{params[:place][:name]}", :radius => 1000)

            # If no spots for the data received, we include it in Google
            if spots.empty?
              address = {
                          :location => {
                            :lat => latitude,
                            :lng => longitude
                          },
                          :accuracy => 50,
                          :name => params[:place][:name],
                          :types => [params[:place][:types]]
                        }
              Rails.logger.debug address.inspect
              result = HTTParty.post("https://maps.googleapis.com/maps/api/place/add/json?sensor=true&key=#{GOOGLE_API_KEY}",
                                      :body => address.to_json,
                                      :headers => { 'Content-Type' => 'application/json' }
                                    )
              Rails.logger.debug result.inspect
              if result['reference'].present? && result['id'].present?
                reference_value = result['reference']+'||'+result['id']
                automatically_created = false
              end
            else
              # In case there is an existing spot, we use it to create reference_value
              spot = spots.first
              reference_value = spot.reference+'||'+spot.id
            end
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

        if parent.present?
          parent.update_attributes({place_ids: parent.place_ids + [@place.id]}, without_protection: true)
        end

        # When a new place was added to Google, data needs to be added to Places table
        if !automatically_created
          @place.update_attributes place_params
        end

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
end
