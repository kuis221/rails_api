class DocumentsController < FilteredController

  respond_to :js, only: [:create, :new, :processing_status]

  belongs_to :event, :campaign, :polymorphic => true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  helper_method :describe_filters

  skip_load_and_authorize_resource

end