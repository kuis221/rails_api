class PhotosController < InheritedResources::Base
  respond_to :js, only: [:create, :new, :processing_status]

  belongs_to :event, optional: true

  skip_load_and_authorize_resource only: [:new, :create]
  before_action :authorize_create, only: [:new, :create]

  include DeactivableHelper
  include PhotosHelper

  custom_actions collection: [:processing_status]

  defaults resource_class: AttachedAsset

  load_and_authorize_resource class: AttachedAsset, through: :parent, except: [:processing_status]

  helper_method :describe_filters

  def processing_status
    @photos = parent.photos.find(params[:photos])
  end

  protected

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(attached_asset: [:direct_upload_url])[:attached_asset]
  end

  def authorize_create
    authorize! :create_photo, parent
  end
end
