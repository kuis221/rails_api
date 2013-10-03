class DocumentsController < InheritedResources::Base

  respond_to :js, only: [:create, :new, :processing_status]

  belongs_to :event, :campaign, :polymorphic => true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  load_and_authorize_resource class: AttachedAsset, through: :parent

  helper_method :describe_filters
end