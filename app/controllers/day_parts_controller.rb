class DayPartsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  authorize_resource

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  protected
    def collection_to_json
      collection.map{|day_part| {
        :id => day_part.id,
        :name => day_part.name,
        :description => day_part.description,
        :status => day_part.active? ? 'Active' : 'Inactive',
        :active => day_part.active?,
        :links => {
            edit: edit_day_part_path(day_part),
            show: day_part_path(day_part),
            activate: activate_day_part_path(day_part),
            deactivate: deactivate_day_part_path(day_part),
            delete: day_part_path(day_part)
        }
      }}
    end

end