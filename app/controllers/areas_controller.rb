class AreasController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_places, :add_places]

  load_and_authorize_resource except: :index

  def autocomplete
    buckets = []

    # Search areas
    search = Sunspot.search(Area) do
      keywords(params[:q]) do
        fields(:name)
      end
    end
    buckets.push(label: "Areas", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    render :json => buckets.flatten
  end

  private
    def collection_to_json
      collection.map{|area| {
        :id => area.id,
        :name => area.name,
        :description => area.description,
        :status => area.active? ? 'Active' : 'Inactive',
        :active => area.active?,
        :links => {
            edit: edit_area_path(area),
            show: area_path(area),
            activate: activate_area_path(area),
            deactivate: deactivate_area_path(area)
        }
      }}
    end

end