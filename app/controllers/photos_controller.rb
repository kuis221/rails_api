class PhotosController < FilteredController
  respond_to :js, only: [:create, :new, :processing_status]

  belongs_to :event, optional: true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  helper_method :describe_filters

  def processing_status
    @photos = parent.photos.find(params[:photos])
  end

end