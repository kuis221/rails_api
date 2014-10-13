# Areas-Campaigns Controller class
#
# This class handle the requests for managing the association
# between areas and campaigns
class AreasCampaignsController < FilteredController
  respond_to :js, only: [:edit, :update]

  defaults finder: :find_by_area_id!

  belongs_to :campaign

  def add_place
    return unless params[:areas_campaign][:reference].present?
    place_reference = resource.place_reference(params[:areas_campaign][:reference])
    resource.inclusions = (resource.inclusions + [place_reference.id]).uniq
    resource.save
  end

  def exclude_place
    resource.exclusions = (resource.exclusions + [params[:place_id].to_i]).uniq
    resource.save
  end

  def include_place
    resource.exclusions = resource.exclusions - [params[:place_id].to_i]
    resource.save
  end

  protected

  def modal_dialog_title
    I18n.translate(
      "modals.title.#{resource.new_record? ? 'new' : 'edit'}.areas_campaign",
      name: resource.area.try(:name))
  end
end
