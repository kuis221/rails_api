# Attached Assets Controller class
#
# This class handle the requests for managing the Attached Assets
#
# TODO: Move this to photos controller and remove this controller
class AttachedAssetsController < InheritedResources::Base
  respond_to :js, only: [:rate]

  def rate
    resource.update_attributes(params.permit(:rating))
    render text: nil
  end
end
