class PlacesController < FilteredController
  actions :index, :new, :create
  belongs_to :area, :campaign, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]

  def create
    reference_value = params[:place][:reference]
    automatically_created = true

    if params[:add_new_place].present?
      address_txt = URI::encode("#{params[:place][:street_number]},
                                 #{params[:place][:route]},
                                 #{params[:place][:city]},
                                 #{params[:place][:state]},
                                 #{params[:place][:zipcode]}
                                 #{params[:place][:country]}")
      data = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address_txt}&sensor=true").read)
      if data['results'].count > 0
        latitude = data['results'].first['geometry']['location']['lat']
        longitude = data['results'].first['geometry']['location']['lng']
        if latitude.present? && longitude.present?
          api_client = GooglePlaces::Client.new(GOOGLE_API_KEY)
          spots = api_client.spots(latitude, longitude, keyword: "#{params[:place][:name]} #{params[:place][:street_number]}", :radius => 1000)

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

            result = HTTParty.post("https://maps.googleapis.com/maps/api/place/add/json?sensor=true&key=#{GOOGLE_API_KEY}",
                                    :body => address.to_json,
                                    :headers => { 'Content-Type' => 'application/json' }
                                  )

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
      end

      @from_new_place_form = true
    end

    if reference_value and !reference_value.nil? and !reference_value.empty?
      reference, place_id = reference_value.split('||')
      @place = Place.find_or_create_by_place_id(place_id, {reference: reference})
      parent.update_attributes({place_ids: parent.place_ids + [@place.id]}, without_protection: true)

      # When a new place was added to Google, data needs to be added to Places table
      if !automatically_created
        @place.street_number = params[:place][:street_number]
        @place.route = params[:place][:route]
        @place.city = params[:place][:city]
        @place.state = params[:place][:state]
        @place.zipcode = params[:place][:zipcode]
        @place.country = params[:place][:country]
        @place.save
      end
    else
      render 'new_place'
    end
  end

  def destroy
    @place = Place.find(params[:id])
    parent.places.delete(@place)
  end
end
