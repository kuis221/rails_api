class PhotosController < FilteredController
  belongs_to :event, optional: true

  include DeactivableHelper

  defaults :resource_class => AttachedAsset

  respond_to :js, only: :create

  skip_load_and_authorize_resource
end