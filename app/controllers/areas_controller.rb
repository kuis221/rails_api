class AreasController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  load_and_authorize_resource except: :index

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

    def sort_options
      {
        'name' => { :order => 'areas.name' },
        'description' => { :order => 'areas.description' },
        'active' => { :order => 'areas.active' }
      }
    end

end