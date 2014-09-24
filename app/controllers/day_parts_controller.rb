# Day Parts Controller class
#
# This class handle the requests for the Day Parts
#
class DayPartsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def autocomplete
    buckets = autocomplete_buckets(
      day_parts: [DayPart]
    )
    render json: buckets.flatten
  end

  protected

  def permitted_params
    params.permit(day_part: [:name, :description])[:day_part]
  end

  def facets
    @facets ||= Array.new.tap do |f|
      f.push(label: 'Active State', items: %w(Active Inactive).map do |x|
        build_facet_item(label: x, id: x, name: :status, count: 1)
      end)
    end
  end
end