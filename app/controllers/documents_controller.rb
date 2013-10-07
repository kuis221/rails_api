class DocumentsController < InheritedResources::Base

  respond_to :js, only: [:create, :new]

  belongs_to :event, :campaign, :polymorphic => true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  load_and_authorize_resource class: AttachedAsset, through: :parent

  helper_method :describe_filters


  protected
    def build_resource_params
      [permitted_params || {}]
    end
    def permitted_params
      params.permit(attached_asset: [:direct_upload_url])[:attached_asset]
    end
end