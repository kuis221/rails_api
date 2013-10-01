class PhotosController < InheritedResources::Base
  respond_to :js, only: [:create, :new, :processing_status]

  belongs_to :event, optional: true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  load_and_authorize_resource class: AttachedAsset, through: :parent

  helper_method :describe_filters

  def processing_status
    @photos = parent.photos.find(params[:photos])
  end

end