ActiveAdmin.register Place do
  config.clear_action_items!
  actions :index, :show, :edit, :update

  filter :name
  filter :city
  filter :state
  filter :country, :as => :select, :collection => proc { Country.all }
  filter :zipcode
  filter :td_linx_code

  form do |f|
    f.inputs "Details" do
      f.input :name
    end

    f.inputs "Address" do
      f.input :formatted_address
      f.input :street_number, label: "Address 1"
      f.input :route,  label: "Address 2"
      f.input :zipcode
      f.input :city
      f.input :state
      f.input :country
      f.input :td_linx_code
    end
    f.actions
  end

  index do
    column :name
    column :city
    column :state
    column :country
    column :types
    actions

  end

  collection_action :migrated_venues, :method => :get do
    @migrations = Legacy::DataMigration.joins('INNER JOIN places pl ON pl.id=local_id AND local_type=\'Place\'').where(local_type: 'Place').search(params[:q]).order('pl.name').page(params[:page])
  end

  member_action :suggest_fix, method: :get do
    @migration = Legacy::DataMigration.where(local_type: 'Place', local_id: resource.id).first
    name  = @migration.remote.name

    @suggested = @migration.remote.find_options_in_api(5)
  end

  member_action :fix, method: :put do
    @migration = Legacy::DataMigration.where(local_type: 'Place', local_id: resource.id).first
    reference = params[:fix][:selection]
    new_place = nil
    if reference == 'account'
      new_place = Place.new(@migration.remote.migration_attributes)
      new_place.save validate: false
    elsif reference =~ /\A[0-9]+\z/
      new_place = Place.find(reference)
    else
      reference, place_id = reference.split('||')
      client = GooglePlaces::Client.new(GOOGLE_API_KEY)
      spot = client.spot(reference)
      new_place = Place.load_by_place_id(spot.id, spot.reference)
      new_place.save if new_place.new_record?
    end

    unless new_place.nil?
      ActiveRecord::Base.transaction do
        @migration.update_column(:local_id, new_place.id)
        Event.select('events.*').joins('INNER JOIN data_migrations ON data_migrations.local_type=\'Event\' AND data_migrations.local_id=events.id').where(place_id: resource.id).each do |event|
          event.place = new_place
          event.save(validate: false)
        end
      end
    end
  end


  controller do
    def permitted_params
      params.permit(:place => [:name, :formatted_address, :street_number, :route, :zipcode, :city, :state, :country, :td_linx_code])
    end
  end
end
