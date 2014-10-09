# Areas Controller class
#
# This class handle the requests for managing the Areas
class AreasController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:cities]

  belongs_to :place, optional: true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  skip_authorize_resource only: [:add, :remove]

  custom_actions member: [:select_places, :add_places, :add_to_campaign]

  def autocomplete
    buckets = autocomplete_buckets(
      areas: [Area]
    )
    render json: buckets.flatten
  end

  def create
    create! do |success, _|
      success.js do
        parent.areas << resource if parent? && parent
        render :create
      end
    end
  end

  def cities
    render json: resource.cities.map(&:name)
  end

  private

  def permitted_params
    params.permit(area: [:name, :description])[:area]
  end

  def facets
    @facets ||= Array.new.tap do |f|
      f.push(
        label: 'Active State',
        items: %w(Active Inactive).map do |x|
          build_facet_item(label: x, id: x, name: :status, count: 1)
        end
      )
    end
  end
end
