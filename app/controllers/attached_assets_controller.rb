class AttachedAssetsController < FilteredController
  respond_to :js, only: [:rate]

  def rate
    resource.update_attributes(params.permit(:rating))
    render :text => ''
  end
end