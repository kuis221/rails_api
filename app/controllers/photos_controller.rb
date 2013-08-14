class PhotosController < FilteredController
  respond_to :js, only: :create

  belongs_to :event, optional: true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  helper_method :describe_filters

  skip_load_and_authorize_resource

end