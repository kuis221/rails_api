class AttachedAssetsController < FilteredController
  respond_to :js, only: [:rate]
  
  def update
    a = AttachedAsset.find params[:id]
    a.update_attributes({:rating => params[:rate_value]})
    render :text => ''
  end
  
  
end