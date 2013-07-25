class PhotosController < FilteredController

  defaults :resource_class => AttachedAsset

  respond_to :js, only: :create
  belongs_to :event, optional: true


  skip_load_and_authorize_resource

end